<template>
  <div>
    <UsernameInput @child-event="handleChildEvent"/>
    <Camera v-if="isCameraVisible"/>
  </div>
</template>

<script>
import UsernameInput from './UserNameInput.vue';
import Camera from './Camera.vue';

export default {
  components: {
    UsernameInput,
    Camera
  },
  data() {
    return {
      isCameraVisible: false,
      username:''
    };
  },
  methods: {
    showCamera() {
      this.isCameraVisible = true; // Show the camera UI
    },
    handleChildEvent(message){
      this.username = message;
      this.showCamera();
    }
  }
};
</script>
