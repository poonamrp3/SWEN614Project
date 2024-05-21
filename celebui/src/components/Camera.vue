<template>
  <div v-if="isPopUpVisible" class="popup-message">
    <div class="popup-content">
      <p>{{ message }}</p>
      <div>
        <button @click="confirm(true)">Yes</button>
        <button @click="confirm(false)">No</button>
      </div>
    </div>
  </div>

  <div class="camera" v-if="isPopUpVisible && isPopUpYes">
    <div class="wrapper">
      <button @click="closeLoginPopUp" class="button-close">x</button>
      <span class="image-label">Here is your look alike</span>
      <div class="image-boxes">
        <div class="image-box">
          <img v-if="lookalikeImage" v-bind:src="'data:image/gif;base64,'+ lookalikeImage" class="image" alt="Look-alike Image">
          <button @click="nextImage">Next LookAlike</button>
        </div>
      </div>
      <button @click="takeSnapAgain" class="button-snap">Wanna take a new snap?</button>
    </div>
  </div>

  <div class="camera" v-if="isTakePhoto">
    <div class="wrapper">
      <button @click="closeCamera" class="button-close">x</button>
      <button v-show="!isPhotoSubmitted" @click="toggleCamera" class="button-snap">{{ isCameraOpen ? 'Close Camera' : 'Take Snap' }}</button>
      
      <div class="video-container" v-show="!isPhotoSubmitted">
        <video v-show="isCameraOpen" class="camera-video" ref="camera" :width="450" :height="337" autoplay playsinline></video>
        <canvas v-show="isPhotoTaken" class="canvas-photo" ref="canvas" :width="450" :height="337"></canvas>
      </div>

      <button v-if="isCameraOpen && !isPhotoTaken" class="button-snap" @click="takePhoto">Snap!</button>
      <button v-show="isPhotoTaken && !isPhotoSubmitted" @click="submitImage" class="camera-download">Submit</button>
      <div v-show="sentImage && images_received">
        <span class="image-label">Here is your look alike</span>
        <div class="image-boxes">
          <div class="image-box">
            <img v-if="sentImage" :src="sentImage" class="image" alt="Captured Image">
          </div>
          <div class="image-box">
            <img v-if="lookalikeImage" v-bind:src="'data:image/gif;base64,'+ lookalikeImage" class="image" alt="Look-alike Image">
            <button @click="nextImage">Next LookAlike</button>
          </div>
        </div>
      </div>
      <div v-if="loading" class="loading">Loading...</div>
      <button v-if="!loading && sentImage && lookalikeImage" @click="tryAgain" class="button-snap">Try Again</button>

    </div>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'CameraComponent',
  data() {
    return {
      isCameraOpen: false,
      isPhotoTaken: false,
      isPhotoSubmitted: false,
      capturedImageData: null,
      sentImage: '',
      lookalikeImage: '',
      images_received_current_index:0,
      images_received: null,
      loading: false,
      apiUrl: process.env.VUE_APP_API_UPLOAD_URL,
      apigetUrl: process.env.VUE_APP_API_GET_URL,
      getMsg:'',
      isTakePhoto : false,
      message:'Wanna see old image?',
      isPopUpVisible : false,
      isPopUpYes : false,
      count : 0
    }
  },
  mounted() {
      this.getUserDataOnLogin();
  },
  methods: {
    // Confirm the user's choice and determine the action
    confirm(answer) {
      if(answer){
        this.isPopUpYes = true
      } else {
        this.isTakePhoto = true
        this.createCameraElement();
      }
    },
    nextImage(){
      if(this.images_received_current_index == 5){
        this.images_received_current_index = 0
      }
      this.lookalikeImage = this.images_received[this.images_received_current_index];
      this.images_received_current_index +=1;
    },
    // Take a snap again if requested by the user
    takeSnapAgain(){
      this.isTakePhoto = true,
      this.createCameraElement();
    },
    // Create camera element and open camera
    createCameraElement() {
      const constraints = {
        audio: false,
        video: true
      };

      navigator.mediaDevices
        .getUserMedia(constraints)
        .then(stream => {
          this.$refs.camera.srcObject = stream;
        })
        .catch(error =>{
          console.log(error)
          alert("The browser unable to open camera.")
        });
    },
    // Stop camera stream
    stopCameraStream() {
      const tracks = this.$refs.camera.srcObject.getTracks();
      tracks.forEach(track => {
        track.stop();
      });
    },
    // Toggle camera status (open/close)
    toggleCamera() {
      if (this.isCameraOpen) {
        this.isCameraOpen = false;
        this.isPhotoTaken = false;
        this.stopCameraStream();
      } else {
        this.isCameraOpen = true;
        this.isPhotoTaken = false;
        this.createCameraElement();
      }
    },
    // Take a photo
    takePhoto() {
      const context = this.$refs.canvas.getContext('2d');
      const photoFromVideo = this.$refs.camera;
      context.drawImage(photoFromVideo, 0, 0, 450, 337);
      this.capturedImageData = this.$refs.canvas.toDataURL('image/jpeg');
      this.isPhotoTaken = true;
      this.isCameraOpen = false;
    },
    // Submit captured image
    submitImage() {
      if (!this.capturedImageData) {
        alert('No image captured. Try again!');
        return;
      }

      this.isPhotoSubmitted = true;
      this.loading = true; // Show loading sign
      const jsonData = {
        image: this.capturedImageData,
        imageName : this.$parent.username
      };

      axios.post(this.apiUrl, jsonData, {
        headers: {
          'Content-Type': 'application/json'
        }}
      )
      .then(response => {
        console.log(response)
        setTimeout(() => {
          this.getUserData()
        }, 7000);
        this.count = 0
      })
      .catch(error =>{
        console.log(error)
        this.handleErrorPost()
      });
    },
    // Handle errors occurred during POST request
    handleErrorPost(){
      alert('Unable to capture Image, snap your picture again');
      this.loading = false // Hide loading sign
      this.tryAgain();
    },

    getUserData() {
      this.getMsg = 'The image for ' + this.$parent.username + ' was not processed yet, try again later'
      axios.get(this.apigetUrl + '/' + this.$parent.username)
        .then(response => {
          console.log('API Response of get URL:', response);
          this.loading = false;
          this.sentImage = this.capturedImageData;
          this.images_received = response.data;
          this.images_received_current_index = 0;
          this.nextImage();
          // this.lookalikeImage = response.data;
        })
        .catch(error => {
          console.log('API Response of get error URL:', error);
          console.log(this.count)

          if (error.response != null && error.response.data != null &&
          this.getMsg === error.response.data) {
            setTimeout(() => {
              if (this.count >= 35) {
                alert('Sorry! unable to find your look like, snap your picture again');
                this.tryAgain();
              } else {
                this.count += 1;
                this.getUserData();
              }
            }, 1000);
          } else {
             alert('Sorry! unable to find your look like, snap your picture again');
             this.tryAgain();
          }

        });
    },
    // Get user data on login
    getUserDataOnLogin() {
      axios.get(this.apigetUrl + '/' + this.$parent.username) 
        .then(response => {
          console.log('API get response of get after login URL:', response);
          this.images_received = response.data;
          this.images_received_current_index = 0;
          this.nextImage();
          // this.lookalikeImage = response.data;
          this.isPopUpVisible = true
        })
        .catch(error =>{
          console.log("API get response login:" ,error)
          this.handleErrorOnLogin()
        });
    },
    // Handle errors occurred during login
    handleErrorOnLogin(){
      this.isTakePhoto = true
      this.createCameraElement();
    },
    // Close camera
    closeCamera() {
      this.isCameraOpen = false;
      this.isPhotoTaken = false;
      this.stopCameraStream();
      this.$parent.isCameraVisible = false;
    },
    // Close login pop-up
    closeLoginPopUp(){
      this.isPopUpVisible = false
      this.isPopUpYes = false
    },
    // Try again to capture image
    tryAgain() {
      // Reset all data and UI to try again
      this.isPhotoSubmitted = false;
      this.sentImage = '';
      this.lookalikeImage = '';
      this.images_received = null;
      this.images_received_current_index = 0;
      this.loading = false;
      this.isCameraOpen = false;
      this.isPhotoTaken = false;
      this.toggleCamera(); // Open the camera again
    }
  }
};
</script>

<style scoped>
.camera {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
}

.wrapper {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  width: 50%;
  height: 90%;
  background-color: white;
  border: solid 2px rgb(223, 114, 250);
}

.button-close {
  position: absolute;
  top: 50px;
  right: 50px;
  width: 25px;
  height: 30px;
  font-size: 20px;
  background-color: transparent;
  border: none;
  cursor: pointer;
}

.button-snap,
.camera-download {
  width: 140px;
  height: 40px;
  margin: 10px 0;
  font-size: 16px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.button-snap:hover,
.camera-download:hover {
  background-color: #45a049;
}

.video-container {
  display: flex;
  flex-direction: row; /* Change to row */
}

.image-boxes {
  display: flex;
  justify-content: space-between; /* Space between image boxes */
  margin-top: 20px;
}

.image-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 200px;
  height: 250px; /* Set a fixed height for the image boxes */
  object-fit: cover;
  border: 1px solid #ccc; /* Add a thin border */
  padding: 10px; /* Add padding to create space around the images */
}

.image-label {
  font-size: 18px;
  margin-bottom: 5px;
}

.image {
  width: 100%;
  height: 100%; /* Ensure the image fills its container */
  object-fit: cover; /* Maintain aspect ratio and cover the container */
}

.popup-message {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background-color: white;
  border: 1px solid #ccc;
  padding: 20px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}

.popup-content {
  text-align: center;
}

.popup-content button {
  margin-top: 15px; /* Increase margin between buttons */
  width: 120px; /* Decrease button width */
  height: 35px; /* Decrease button height */
  font-size: 14px; /* Decrease font size */
  background-color: #4CAF50; /* Use the same background color as other buttons */
  color: white; /* Set text color to contrast with background */
  border: none; /* Remove borders */
  border-radius: 5px; /* Apply border radius for rounded corners */
  cursor: pointer;
  transition: background-color 0.3s; /* Add transition effect */
}

.popup-content button:hover {
  background-color: #45a049; /* Darker shade on hover */
}

.popup-content button:first-child {
  margin-right: 10px; /* Add margin between buttons */
}
.image-label {
  font-size: 18px;
  font-weight: bold; /* Add bold font weight */
  margin-bottom: 10px; /* Increase bottom margin */
}

.loading{
  font-size: 24px;
}
</style>
