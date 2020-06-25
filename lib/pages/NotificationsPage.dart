import 'package:Askforum/pages/HomePage.dart';
import 'package:Askforum/pages/PostScreenPage.dart';
import 'package:Askforum/pages/ProfilePage.dart';
import 'package:Askforum/widgets/CImageWidget.dart';
import 'package:Askforum/widgets/HeaderWidget.dart';
import 'package:Askforum/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tAgo;

class NotificationsPage extends StatefulWidget {



  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}




class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: "Notification"),
      body: Container(
        child: FutureBuilder(
          future: retriveNotification(),
          builder: (context, dataSnapshot){
            if(!dataSnapshot.hasData){
              return circularProgress();
            }
            return ListView(
              children: dataSnapshot.data,
            );
          },
        ),
      ),
    );
  }
  retriveNotification() async{
    QuerySnapshot querySnapshot = await activityFeedReference.document(currentUser.id)
        .collection("feedItems").orderBy("timestamp",descending: true).limit(60).getDocuments();
    List<NotificationsItem> notificationItem = [];

    querySnapshot.documents.forEach((document) {
      notificationItem.add(NotificationsItem.fromDocument(document));
    });
    return notificationItem;
   }
}

String notificationItemText;
Widget mediaPreview;

class NotificationsItem extends StatelessWidget {

  final String username;
  final String type;
  final String commentData;
  final String postId;
  final String userId;
  final String userProfileImg;
  final String url;
  final Timestamp timestamp;

  NotificationsItem({
    this.timestamp,
    this.url,
    this.username,
    this.postId,
    this.commentData,
    this.type,
    this.userProfileImg,
    this.userId,
});


  factory NotificationsItem.fromDocument(DocumentSnapshot documentSnapshot)
  {
    return NotificationsItem(
      username: documentSnapshot["username"],
      timestamp: documentSnapshot["timestamp"],
      url: documentSnapshot["url"],
      postId: documentSnapshot["postId"],
      commentData: documentSnapshot["commentData"],
      type: documentSnapshot["type"],
      userProfileImg: documentSnapshot["userProfileImg"],
      userId: documentSnapshot["userId"],


    );
  }

  @override
  Widget build(BuildContext context) {

    configureMediaPreview(context);

    return Padding(
        padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: ()=>displayUserProfile(context, userProfileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.0,
                ),
                children: [
                  TextSpan(
                    text: username, style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: " $notificationItemText"
                  ),
                ]
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(
            tAgo.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
  configureMediaPreview(context){
    if(type == "comment" || type == "Like"){
      mediaPreview = GestureDetector(
        onTap: ()=> displayOwnProfile(context,userProfileId: currentUser.id),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16/9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(fit: BoxFit.cover,image: CachedNetworkImageProvider(url)),
              ),
            ),
          ),
        ),
      );
    }
    else{
      mediaPreview = Text("");
    }
    if(type == "Like"){
      notificationItemText = "Liked your post.";
    }
    else if(type == "comment"){
      notificationItemText = "replied: $commentData .";
    }
    else if(type == "follow"){
      notificationItemText = "started following you .";
    }
    else{
      notificationItemText = "Error, Unknown type = $type .";
    }
  }

  displayOwnProfile(BuildContext context,{String userProfileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: currentUser.id)));
  }

  displayUserProfile(BuildContext context,{String userProfileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: userProfileId)));
  }
}
