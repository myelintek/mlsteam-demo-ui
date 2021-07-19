import Vue from 'vue'
import VueRouter from 'vue-router'
import Classification from '../views/Classification.vue'

Vue.use(VueRouter)

const routes = [
  {
    path: '/',
    name: 'Classification',
    component: Classification
  }
]

const router = new VueRouter({
  // mode: 'history',
  base: process.env.BASE_URL,
  routes
})

export default router
