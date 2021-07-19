<template>
  <v-app>
    <v-app-bar
      app
      color="white"
      dark
    >
      <v-app-bar-nav-icon @click.stop="drawer = !drawer" color="parimary"></v-app-bar-nav-icon>
      <div class="d-flex align-center">
        <v-img
          alt="MLSteam"
          class="shrink mr-2"
          contain
          src="@/assets/logo.png"
          transition="scale-transition"
          width="200"
        />
      </div>

      <v-spacer></v-spacer>
    </v-app-bar>

    <v-main>
      <router-view/>
    </v-main>
  </v-app>
</template>

<script>

export default {
  name: 'App',

  data: () => ({
    drawer: false
  })
}
</script>
