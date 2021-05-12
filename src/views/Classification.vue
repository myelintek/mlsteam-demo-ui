<template>
  <v-container fill-height fluid>
    <v-row align="center" justify="center">
      <v-col :key="1" md="4">
        <v-file-input
          v-model="files"
          color="primary accent-4"
          counter
          label="File input"
          multiple
          placeholder="Select your images"
          prepend-icon="mdi-paperclip"
          outlined
          :show-size="1000"
        >
          <template v-slot:selection="{ index, text }">
            <v-chip
              v-if="index < 2"
              color="primary accentＳ-4"
              dark
              label
              small
            >
              {{ text }}
            </v-chip>
            <span
              v-else-if="index === 2"
              class="overline grey--text text--darken-3 mx-2"
            >
              +{{ files.length - 2 }} File(s)
            </span>
          </template>
        </v-file-input>
        <div class="d-flex justify-center">
        <v-btn class="col" @click="upload">upload</v-btn>
        </div>
      </v-col>
    </v-row>
    <v-row v-if="images.length !== 0" style="height: 300; overflow:auto;">
      <v-col
        v-for="(img, i) in images"
        :key="i"
        class="d-flex child-flex"
        cols="2"
      >
        <v-card :loading="img.status == 'pending'">
          <v-img :src="img.url" aspect-ratio="1" class="grey lighten-2">
            <template v-slot:placeholder>
              <v-row
                class="fill-height ma-0"
                align="center"
                justify="center"
              >
                <v-progress-circular
                  indeterminate
                  color="grey lighten-5"
                ></v-progress-circular>
              </v-row>
            </template>
          </v-img>
          <v-cart-text v-if="img.status === 'success'">
            {{img.result}}
          </v-cart-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import { mapActions, mapState } from 'vuex'

export default {
  name: 'Classification',
  data: () => ({
    files: []
  }),
  computed: {
    ...mapState(['images', 'results'])
  },
  methods: {
    ...mapActions(['enqueue']),
    upload () {
      const self = this
      this.files.forEach(f => {
        console.log('enqueue', f)
        self.enqueue(f)
      })
      this.files.splice(0, this.files.length)
    }
  }
}
</script>

<style>
</style>
