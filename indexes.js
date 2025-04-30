<script type="module">
  // Import the functions you need from the SDKs you need
  import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
  import { getAnalytics } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-analytics.js";
  // TODO: Add SDKs for Firebase products that you want to use
  // https://firebase.google.com/docs/web/setup#available-libraries

  // Your web app's Firebase configuration
  // For Firebase JS SDK v7.20.0 and later, measurementId is optional
  const firebaseConfig = {
    apiKey: "AIzaSyDmskTQzdtZyr539OBRe7x6-sAHheB3Gq4",
    authDomain: "taxease-ac6ca.firebaseapp.com",
    projectId: "taxease-ac6ca",
    storageBucket: "taxease-ac6ca.firebasestorage.app",
    messagingSenderId: "398490907644",
    appId: "1:398490907644:web:fdc6267be4ff9742a7b879",
    measurementId: "G-NX3WN0T9KB"
  };

  // Initialize Firebase
  const app = initializeApp(firebaseConfig);
  const analytics = getAnalytics(app);
</script>