import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'vue-axios'

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
      await context.commit('enlist', image)
      // context.dispatch('process')
    },
    process: (context) => {
      const q = context.state.queue
      if (q.length === 0) {
        return
      }
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
        for (const i in res.data) {
          context.commit('finishInference', images[i].name, res.data[i])
        }
      })
      context.dispatch('process')
    }
  },
  modules: {
  }
})
