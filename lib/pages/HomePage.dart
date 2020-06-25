import 'dart:io';
import 'package:Askforum/models/user.dart';
import 'package:Askforum/pages/CreateAccountPage.dart';
import 'package:Askforum/pages/NotificationsPage.dart';
import 'package:Askforum/pages/ProfilePage.dart';
import 'package:Askforum/pages/SearchPage.dart';
import 'package:Askforum/pages/UploadPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'TimeLinePage.dart';

final GoogleSignIn gSignIn = GoogleSignIn();
final userReference = Firestore.instance.collection("users");
final StorageReference storageReference = FirebaseStorage.instance.ref().child("Posts Pictures");
final postsReference = Firestore.instance.collection("posts");
final activityFeedReference = Firestore.instance.collection("feed");
final commentsReference = Firestore.instance.collection("comments");
final followersReference = Firestore.instance.collection("followers");
final followingReference = Firestore.instance.collection("following");
final timelineReference = Firestore.instance.collection("timeline");

final DateTime timestamp = DateTime.now();
User currentUser;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool isSignedIn = false;
  PageController pageController;
  int getPageIndex = 0 ;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void initState(){
    super.initState();

    pageController = PageController();

    gSignIn.onCurrentUserChanged.listen((gSigninAccount) {
      controlSignIn(gSigninAccount);
    }, onError: (gError){
      print("Error Message: " + gError);
    });

    gSignIn.signInSilently(suppressErrors: false).then((gSignInAccount) {
      controlSignIn(gSignInAccount);
    }).catchError((gError){
      print("Error Message: " + gError);
    });
  }

  controlSignIn(GoogleSignInAccount signInAccount) async {
    if(signInAccount != null){
      await saveUserInfoToFireStore();
      setState(() {
        isSignedIn = true;
      });
    }
    else{
      setState(() {
        isSignedIn = false;
      });

      configureRealTimePushNotification();
    }

  }

  configureRealTimePushNotification(){
    final GoogleSignInAccount gUser = gSignIn.currentUser;
    if(Platform.isIOS){
      getIOSPermissions();
    }
    _firebaseMessaging.getToken().then((token) {
      userReference.document(gUser.id).updateData({"androidNotificationToken": token});
    });
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> msg) async{
      final String recipientId = msg["data"]["recipient"];
      final String body = msg["notification"]["body"];

      if(recipientId == gUser.id){
        SnackBar snackBar = SnackBar(
          backgroundColor: Colors.grey,
          content: Text(body, style: TextStyle(color: Colors.black),overflow: TextOverflow.ellipsis,),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
      }
    );
  }

  getIOSPermissions(){
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true,badge: true,sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Setting Registered:  $settings");
    });

  }

  saveUserInfoToFireStore() async {
    final GoogleSignInAccount gCurrentUser = gSignIn.currentUser;
    DocumentSnapshot documentSnapshot = await userReference.document(gCurrentUser.id).get();

    if(!documentSnapshot.exists){
      final username =  await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAccountPage()));
      userReference.document(gCurrentUser.id).setData({
        "id": gCurrentUser.id,
        "profileName": gCurrentUser.displayName,
        "username": username,
        "url": gCurrentUser.photoUrl,
        "email": gCurrentUser.email,
        "bio": "",
        "timestamp": timestamp,
      });

      await followersReference.document(gCurrentUser.id).collection("userFollowers").document(gCurrentUser.id).setData({});

      documentSnapshot = await userReference.document(gCurrentUser.id).get();
    }
    currentUser = User.fromDocument(documentSnapshot);
  }

  void dispose(){
    pageController.dispose();
    super.dispose();
  }

  loginUser(){
    gSignIn.signIn();
  }

  logoutUser(){
    gSignIn.signOut();
  }

  whenPageChanges(int pageIndex){
    setState(() {
      this.getPageIndex = pageIndex;
    });
  }

  onTapChangePage(int pageIndex){
    pageController.animateToPage(pageIndex, duration: Duration(milliseconds: 400), curve: Curves.bounceInOut);
  }

  Scaffold buildHomeScreen(){
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          TimeLinePage(gCurrentUser: currentUser,),
          SearchPage(),
          UploadPage(gCurrentUser: currentUser,),
          NotificationsPage(),
          ProfilePage(userProfileId: currentUser.id),
        ],
        controller: pageController,
        onPageChanged: whenPageChanges,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: getPageIndex,
        onTap: onTapChangePage,
        activeColor: Colors.red,
        backgroundColor: Theme.of(context).accentColor,
        inactiveColor: Colors.blueGrey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.add , size: 50.0 ,)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none )),
          BottomNavigationBarItem(icon: Icon(Icons.person)),

        ],
      ),
    );

  }

  Scaffold buildSignInScreen(){
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Theme.of(context).accentColor, Theme.of(context).primaryColor],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
                "Ask Forum",
              style: TextStyle(
                fontSize: 92.0,
                color: Colors.deepOrange,
                fontFamily: "Signatra"
              ),
            ),
            GestureDetector(
              onTap: loginUser(),
              child: Container(
                width: 270.0,
                height: 65.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/google_signin_button.png"),
                    fit: BoxFit.cover,
                  )
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if(isSignedIn)
      {
        return buildHomeScreen();
      }
    else {
        return buildSignInScreen();
    }
  }
}
