// Firebase Messaging Service Worker cho Web
// File này cần thiết để Web nhận push notification từ FCM khi app ở background

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// Cấu hình Firebase — phải khớp với firebase_options.dart (web config)
firebase.initializeApp({
  apiKey: 'AIzaSyADIe1uVqbLzg3jRAhAxPgolCRBMnv91ko',
  authDomain: 'smart-room-finder-app-firebase.firebaseapp.com',
  projectId: 'smart-room-finder-app-firebase',
  storageBucket: 'smart-room-finder-app-firebase.firebasestorage.app',
  messagingSenderId: '154072375713',
  appId: '1:154072375713:web:255bd8068bbad4ac462be0',
});

const messaging = firebase.messaging();

// Xử lý notification khi app ở background
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message:', payload);

  const notificationTitle = payload.notification?.title ?? 'Smart Room Finder';
  const notificationOptions = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
