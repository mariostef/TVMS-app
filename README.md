# TravelMiSSion (TVMS)

## a) Installation and usage instructions

### Installation
The installation of the application is simple and does not require specialized knowledge:
1. Download the `app-release.apk` file to your Android device.
2. Enable installation from "Unknown Sources" in your device settings and disable any settings such as "Auto Blocker".
3. Run the file and press "Install".
4. The application requires an active internet connection for your login, and access to location (GPS) and the camera. Therefore, if you are prompted for corresponding permissions, accept them for the proper use of the application.

### Usage (Scenario for the reviewer)
There is the possibility to create a profile either as a traveller or as a company. We suggest that an account is created by the reviewer in the traveller section, or that the following ready-made profile is used (username: `test`, password: `test`), in order to utilize the main functions of the application.

There is a "forgot password" option in a created profile where the password is changed via a recovery code sent to the email you provided.

### Usage steps:
1. **Sign up:** Create your own personalized account by pressing "create account", if you do not already have an account.
2. **Login:** Log in as a Traveller. If you have forgotten your password, press "forgot password", type the email linked to your account, and a personalized one-time code will be sent to you to reset your passwords.
3. **Navigation:** Use the central "Map" button from the navigation menu to see the checkpoints/sights of Athens (e.g., Acropolis Museum, Kallimarmaro). With the button located at the bottom right of the screen, above the navigation menu, the map centers back to your location.
4. **Check-in:** Tap on a checkpoint/sight marked with a star and if you are within the radius (for testing purposes the radius has been set to allow check-in), press "I am here!".
5. **Missions:** You will feel a vibration (Haptic Feedback) and the ability to take a Selfie will be unlocked. Take a photo, which will be saved to your account (described below).
6. **Congratulations screen:** After the photo, you will be transferred to the "Congratulations" screen where you will see the completion percentage (i.e., how many of the city's sights you have unlocked) and the coupons you have won (e.g., 10% discount at a company). You can tap on them, you will see how they change color and stand out on the screen.
7. **Rewards screen:** By pressing the corresponding icon in the navigation menu (left) you can see the list of rewards you have unlocked as well as the bonus reward if you have unlocked all destinations.
8. **File screen:** In the "File" option from the navigation menu (right) you can see the cities you have "unlocked", and by tapping each unlocked city you can browse by swiping the screen left and right through the photos you took.
9. **Partner Mode:** By logging out (icon on the top right) and selecting "Are you a company?" you can log in as a company or create a corporate account by subsequently pressing "create an account". Log in as a Partner to manage coupons and select a subscription package. You select a package by tapping "subscription" at the bottom right of the navigation menu, choose the desired package, accept the terms and press "Pay" (the payment details completion can be left blank). Then manage your coupons and cities by tapping "My Cities" on the bottom left. You can add ("+") or delete cities. By tapping on the desired city you can create coupons by pressing "+", modify them, or delete them. The coupons can be targeted to users of a specific age and gender. Depending on the criteria you have selected, the coupons can appear to some travellers who meet these criteria.

---

## b) Technical Specifications
* **Android SDK Version:** Minimum SDK 24 (Android 5.0 Lollipop) or newer.
* **GPS:** For positioning and confirming a visit (Check-in).
* **Camera:** For taking a selfie.
* **Vibration:** Slight vibration on the mobile phone to notify arrival at a checkpoint.
* **Persistence:** Data is stored in Firebase Firestore (users, coupons, visits) and in SharedPreferences (local session).

---

## c) Differentiation from the phase B prototype
The final application implements all the features of the initial design (Map, Rewards, Archive) with some improvements:
1. **Targeted Rewards:** The implementation now takes into account gender and age group (User Modeling) to offer personalized discounts.
2. **Cloud Sync:** While initially only local storage of photos was planned, the app now also synchronizes photos to Firebase Storage so they are not lost during login/logout.
3. **Message if you have already visited:** If a user taps an attraction they have already visited, it shows the message "You have already visited this destination."
4. **System messages:** Corresponding messages appear in case of an attempted login with invalid credentials.
5. **Introduction of a permanent logout option:** So that the user can log out at any time.

---

## d) Presentation Video
You can watch a short presentation of the application's features at the following link:  
[example video](https://drive.google.com/file/d/1jLlthM1YFLLaS-SnT2gkGJxa9FR8Tbw3/view?usp=drive_link)
---

## e) Application files
* **APK File:** [Download APK](https://drive.google.com/file/d/1u4z_FI4MY0GjSaZsF9iknoAWYL16nIuG/view?usp=sharing)

