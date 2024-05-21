<template>
  <div class="app-container">
    <div class="landing-page" v-if="currentPage === 'landing'">
      <h1>Let's find out which celebrity you look alike</h1>
      <button @click="redirectToUserInput">Let's start</button>
    </div>
    <UserInput v-if="currentPage === 'userInput'" @backToLanding="backToLanding" />
  </div>
</template>

<script>
import UserInput from './UserInput.vue';

export default {
  name: 'App',
  components: {
    UserInput
  },
  data() {
    return {
      currentPage: 'landing'
    };
  },
  methods: {
    redirectToUserInput() {
      this.currentPage = 'userInput';
    },
    backToLanding() {
      this.currentPage = 'landing';
    }
  }
};
</script>

<style scoped>
.app-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
}

.landing-page {
  text-align: center;
}

h1 {
  font-size: 36px;
  margin-bottom: 20px;
}

button {
  background-color: #4CAF50;
  color: white;
  padding: 15px 30px;
  font-size: 18px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  transition: background-color 0.3s;
}

button:hover {
  background-color: #45a049;
}
</style>
