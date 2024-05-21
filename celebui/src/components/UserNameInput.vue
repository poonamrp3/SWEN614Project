<template>
  <div class="username-input">
    <h2>Enter Your Username</h2>
    <div class="input-container">
      <input type="text"
       v-model="inputText"
       placeholder="Enter your username" 
       @input="validateInput"
       class="username-input-box">
      <button @click="clearUsername" class="clear-button">&#x2715;</button>
    </div>
    <span v-if="errorMessage" style="color: red;">{{ errorMessage }}</span>
    <div class="input-line">
      <button v-if="inputText && (errorMessage == '')" 
      @click="sendMessageToParent" class="action-button">Login</button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'UserNameInput',
  data(){
    return{
      inputText:'',
      errorMessage: ''
    }
  },
  methods:{
    sendMessageToParent(){
      this.$emit('child-event', this.inputText);
    },
    validateInput() {
      const regex = /^[a-zA-Z0-9]+$/;
      if (!regex.test(this.inputText)) {
        this.errorMessage = "Enter username with alphabets only.";
      } else if (this.inputText.length > 20) {
        this.errorMessage = "Username should be maximum 20 characters long.";
      } else {
        this.errorMessage = '';
      }
    },
    clearUsername(){
      this.inputText = ''
      this.errorMessage = ''
    }
  }
};
</script>

<style scoped>
.input-container {
  position: relative;
  display: inline-block;
}

.username-input-box {
  padding-right: 30px; /* Adjust this value based on the width of the clear button */
}

.clear-button {
  position: absolute;
  top: 50%;
  right: 5px; /* Adjust this value for positioning */
  transform: translateY(-50%);
  background: none;
  border: none;
  cursor: pointer;
  font-size: 16px;
  color: #4CAF50;
}
/* Center align the elements vertically */
.username-input {
  display: flex;
  flex-direction: column;
  align-items: center;
  font-family: Arial, sans-serif;
}

/* Add space between input lines */
.input-line {
  margin: 10px 0;
}

/* Style the input box */
.username-input-box {
  width: 300px; /* Set the width to your desired size */
  padding: 10px; /* Add padding for better appearance */
  font-size: 16px; /* Adjust font size if needed */
  border: 1px solid #ccc;
  border-radius: 5px;
}

/* Style action buttons */
.action-button {
  padding: 10px 20px;
  font-size: 16px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.action-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.action-button:hover {
  background-color: #45a049;
}
</style>

