import 'dart:async';

import 'package:Askforum/models/user.dart';
import 'package:Askforum/pages/CommentsPage.dart';
import 'package:Askforum/pages/HomePage.dart';
import 'package:Askforum/pages/ProfilePage.dart';
import 'package:Askforum/widgets/CImageWidget.dart';
import 'package:Askforum/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Post extends StatefulWidget {

  final String postId;
  final String ownerId;
  final dynamic Likes;
  final String username;
  final String description;
  final String location;
  final String group;
  final String url;

  Post({
   this.postId,
    this.ownerId,
    this.Likes,
    this.username,
    this.description,
    this.url,
    this.group,
    this.location,
});

  factory Post.fromDocument(DocumentSnapshot documentSnapshot){
    return Post(
      postId: documentSnapshot["postId"],
      ownerId: documentSnapshot["ownerId"],
      Likes: documentSnapshot["Likes"],
      username: documentSnapshot["username"],
      description: documentSnapshot["description"],
      url: documentSnapshot["url"],
      group: documentSnapshot["group"],
      location: documentSnapshot["location"],
    );
  }

  int getTotalNumberOfLikes(Likes){
    if(Likes == null){
      return 0;
    }
    int counter = 0;
    Likes.values.forEach((eachValue){
      if(eachValue == true){
        counter = counter + 1;
      }
    });
    return counter;
  }

  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    Likes: this.Likes,
    username: this.username,
    description: this.description,
    url: this.url,
    group: this.group,
    location: this.location,
    likeCount: getTotalNumberOfLikes(this.Likes),
  );
}

class _PostState extends State<Post> {
  final String postId;
  final String ownerId;
  Map Likes;
  final String username;
  final String description;
  final String location;
  final String group;
  final String url;
  int likeCount;
  bool isLiked;
  bool showUp = false;
  final String currentOnlineUserId = currentUser?.id;

  _PostState({
    this.postId,
    this.ownerId,
    this.Likes,
    this.username,
    this.description,
    this.url,
    this.group,
    this.location,
    this.likeCount,
  });




  @override
  Widget build(BuildContext context) {
    isLiked = (Likes[currentOnlineUserId] == true);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          createPostHead(),
          createPostPicture(),
          createPostFooter(),
        ],
      ),
    );
  }

  createPostHead(){
    return FutureBuilder(
        builder: (context, dataSnapshot){
          if(!dataSnapshot.hasData){
            return circularProgress();
          }
          User user = User.fromDocument(dataSnapshot.data);
          bool isPostOwner = currentOnlineUserId == ownerId;
          return ListTile(
            leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(user.url),backgroundColor: Colors.grey,),
            title: GestureDetector(
              onTap: ()=> displayUserProfile(context, userProfileId: user.id),
              child: Text(
                user.username,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text("Category: $group",style: TextStyle(color: Colors.red),),
                Text("Location: $location",style: TextStyle(color: Colors.white),),
              ],
            ) ,
            isThreeLine: true ,
            trailing: isPostOwner ? IconButton(
              icon: Icon(Icons.more_vert,color: Colors.red,),
              onPressed: () => controlPostDelete(context),
            ) : Text(""),
          );
        },
      future: userReference.document(ownerId).get(),
    );
  }

  controlPostDelete(BuildContext mContext){
    return showDialog(
        context: mContext,
      builder: (context){
          return SimpleDialog(
            title: Text("What do you want?", style: TextStyle(
              color: Colors.white,
          ),),
        children: <Widget>[
          SimpleDialogOption(
        child: Text(
        "Delete this Post",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
        ),
            onPressed: (){
          Navigator.pop(context);
          removeUserPost();
            },
        ),
          SimpleDialogOption(
              child: Text(
                "Cancel",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
              ),
            onPressed: ()=> Navigator.pop(context),
          )
        ],
          );
      }
    );
  }

  removeUserPost() async{
    postsReference.document(ownerId).collection("usersPosts").document(postId).get()
        .then((document){
          if(document.exists){
            document.reference.delete();
          }
    });
    storageReference.child("post_$postId.jpg").delete();

    QuerySnapshot querySnapshot = await activityFeedReference.document(ownerId).collection("feedItems")
    .where("postId", isEqualTo: postId).getDocuments();

    querySnapshot.documents.forEach((document) {
      if(document.exists){
        document.reference.delete();
      }
    });
    QuerySnapshot commentsQuerySnapshot = await commentsReference.document(postId).collection("comments")
    .getDocuments();

    commentsQuerySnapshot.documents.forEach((document) {
      if(document.exists){
        document.reference.delete();
      }
    });
  }
  
  displayUserProfile(BuildContext context,{String userProfileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: userProfileId)));
  }

  removeLike(){
    bool isNotPostOwner = currentOnlineUserId != ownerId;
    if(isNotPostOwner){
      activityFeedReference.document(ownerId).collection("feedItems").document(postId).get().then((document){
        if(document.exists){
          document.reference.delete();
        }
      });
    }
  }

  addLike(){
    bool isNotPostOwner = currentOnlineUserId != ownerId;
    if(isNotPostOwner){
      activityFeedReference.document(ownerId).collection("feedItems").document(postId).setData({
        "type": "Like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "postId": postId,
        "userProfileImg":currentUser.url,
      });
    }
  }

  controlUserLikePost(){
    bool _Liked = Likes[currentOnlineUserId] == true;
    if(_Liked){
      postsReference.document(ownerId).collection("usersPosts").document(postId).updateData({"Likes.$currentOnlineUserId": false});
      removeLike();

      setState(() {
        likeCount= likeCount -1;
        isLiked = false;
        Likes[currentOnlineUserId] = false;
      });
    }
    else if(!_Liked){
      postsReference.document(ownerId).collection("usersPosts").document(postId).updateData({"Likes.$currentOnlineUserId": true});
      addLike();
      setState(() {
        likeCount = likeCount + 1;
        isLiked = true;
        Likes[currentOnlineUserId] = true;
        showUp = true;
      });
      Timer(Duration(milliseconds: 800),(){
        setState(() {
          showUp = false;
        });
      });
    }
  }
  
  
  createPostPicture(){
    return GestureDetector(
      onDoubleTap: () => controlUserLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image.network(url),
          showUp ? Icon(Icons.thumb_up,size: 100.0,color: Colors.red,) : Text(""),

        ],
      ),
    );
  }
  createPostFooter(){
    return Column(
      children: <Widget>[
        Divider(height: 20.0,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only( left: 20.0),
              child: Text("Question: ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold,fontSize: 15.0),),
            ),
            Expanded(
              child: Text(description,style: TextStyle(color: Colors.white,fontSize: 15.0),),
            )
          ],
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.only(top: 40.0, left: 20.0),),
          GestureDetector(
            onTap: () => controlUserLikePost(),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 20.0,
              color: Colors.red,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 20.0 ),),
          GestureDetector(
            onTap: () => displayComments(context,postId: postId,ownerId: ownerId,url:url),
            child: Icon(
              Icons.comment,
              size: 20.0,
              color: Colors.white,
            ),
          ),
        ],
      )  ,
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount Votes",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),

      ],
    );
  }
  displayComments(BuildContext context,{String postId, String ownerId, String url}){
    Navigator.push(context, MaterialPageRoute(builder: (context)
    {
      return CommentsPage(postId: postId,postOwnerId: ownerId,postImageUrl: url);
    }
    ));
  }
}

