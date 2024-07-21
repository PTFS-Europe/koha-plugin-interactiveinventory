<template>
  <Test :csrfToken="csrfToken" />
</template>

<script>
import Test from './test.vue'

export default {
  name: 'Main',
  components: {
    Test
  },
  data() {
    return {
      csrfToken: window.csrf_token // Access the CSRF token from the global scope
    }
  }
}
</script>
