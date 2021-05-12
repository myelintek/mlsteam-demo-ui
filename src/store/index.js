import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios'

Vue.use(Vuex)
const MAX_BATCH = 10
const INFERENCE_API_URL = 'http://100.74.51.8/proxy/u98d33bc/infernece'

export default new Vuex.Store({
  state: {
    images: [],
    queue: []
  },
  mutations: {
    enlist: (state, image) => {
      state.images.push({ name: image.name, url: URL.createObjectURL(image), status: 'pending', result: {} })
      state.queue.push(image)
      console.log('queued image', image)
    },
    finishInference: (state, name, result) => {
      const i = state.images.findIndex((elm) => elm.name === name)
      const img = { ...state.images[i], status: 'success', result: result }
      state.images.splice(i, 1, img)
    },
    failInference: (state, name) => {
      const i = state.images.findIndex((elm) => elm.name === name)
      const img = { ...state.images[i], status: 'fail' }
      state.images.splice(i, 1, img)
    }
  },
  actions: {
    enqueue: async (context, image) => {
      console.log('enlist image', image)
      await context.commit('enlist', image)
      context.dispatch('process')
    },
    process: (context) => {
      console.log('process image')
      const q = context.state.queue
      if (q.length === 0) {
        console.log('no image in queue')
        return
      }
      console.log('image in queue', q)
      const images = []
      while (q.length > 0 && images.length < MAX_BATCH) {
        images.push(q.shift())
      }
      const formData = new FormData()
      images.forEach(file => {
        formData.append('images', file)
      })

      axios.post(INFERENCE_API_URL,
        formData,
        {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        }
      ).then(function (res) {
        console.log('inference finish', res)
        for (const i in res.data) {
          context.commit('finishInference', images[i].name, res.data[i])
        }
      }).catch(function (res) {
        console.log('inference fail', res)
        for (const i in images) {
          context.commit('failInference', images[i].name)
        }
      })
      context.dispatch('process')
    }
  },
  modules: {
  }
})
