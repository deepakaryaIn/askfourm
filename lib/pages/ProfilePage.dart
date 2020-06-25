import 'package:Askforum/models/user.dart';
import 'package:Askforum/pages/EditProfilePage.dart';
import 'package:Askforum/pages/HomePage.dart';
import 'package:Askforum/widgets/HeaderWidget.dart';
import 'package:Askforum/widgets/PostTileWidget.dart';
import 'package:Askforum/widgets/PostWidget.dart';
import 'package:Askforum/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {

  final String userProfileId;
  ProfilePage({this.userProfileId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final String currentOnlineUserId = currentUser.id;
  bool loading = false;
  int countPost = 0;
  List<Post> postsList = [];
  String postOrientation = "grid";
  int countTotalFollowers =0;
  int countTotalFollowings =0;
  bool following  = false;

  
  void initState(){
    getAllProfilePosts();
    getAllFollowers();
    getAllFollowings();
    checkIfAlreadyFollowing();
  }

  getAllFollowers()async{
    QuerySnapshot querySnapshot = await followersReference.document(widget.userProfileId)
        .collection("userFollowers").getDocuments();
    setState(() {
      countTotalFollowers = querySnapshot.documents.length;
    });
  }

  getAllFollowings() async{
    QuerySnapshot querySnapshot = await followingReference.document(widget.userProfileId)
        .collection("userFollowing").getDocuments();
    setState(() {
      countTotalFollowings = querySnapshot.documents.length;
    });
  }

  checkIfAlreadyFollowing() async{
    DocumentSnapshot documentSnapshot = await followingReference
        .document(widget.userProfileId).collection("userFollowers")
        .document(currentOnlineUserId).get();

    setState(() {
      following = documentSnapshot.exists;
    });
  }



  createProfileTopVIew(){
    return FutureBuilder(
      future: userReference.document(widget.userProfileId).get(),
        builder: (context, dataSnaoshot){
          if(!dataSnaoshot.hasData)
            {
              return circularProgress();
            }
          User user = User.fromDocument(dataSnaoshot.data);
          return Padding(padding: EdgeInsets.all(17.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 45.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.url),
                  ),
                  Expanded(
                    flex: 1,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              createColumes("Question", countPost),
                              createColumes("followers", countTotalFollowers),
                              createColumes("following",countTotalFollowings),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              createButton(),
                            ],
                          )
                        ],
                      )
                  )
                ],
              ),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(top:13.0),
                child: Text(
                  user.profileName,
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(top:5.0),
                child: Text(
                  "@ ${user.username}",
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white38,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(top:3.0),
                child: Text(
                  user.bio,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white70,
                  ),
                ),
              )
            ],
          ),);
        },
    );
  }

  Column createColumes(String title, int count){
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 5.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        )
      ],
    );
  }

  createButton(){
    bool ourProfile = currentOnlineUserId == widget.userProfileId;
    if(ourProfile){
      return createButtonTitleAndFunction(title: "Edit Profile", performFunction: editUserProfile);
    }
   else if(following){
      return createButtonTitleAndFunction(title: "Unfollow", performFunction: controlUnfollowUser);
    }
    else if(!following){
      return createButtonTitleAndFunction(title: "follow", performFunction: controlFollowUser);
    }
  }

  controlUnfollowUser(){
    setState(() {
      following =false;
    });
    followersReference.document(widget.userProfileId)
        .collection("userFollowers").document(currentOnlineUserId).get()
        .then((document){
          if(document.exists){
            document.reference.delete();
          }
    });
    followingReference.document(currentOnlineUserId)
        .collection("userFollowing").document(widget.userProfileId).get()
        .then((document){
      if(document.exists){
        document.reference.delete();
      }
    });
    activityFeedReference.document(widget.userProfileId).collection("feedItems").document(currentOnlineUserId).get()
        .then((document) {
          if(document.exists){
            document.reference.delete();
          }
    });

  }

  controlFollowUser(){
    setState(() {
      following = true;
    });
    followersReference.document(widget.userProfileId).collection("userFollowers")
    .document(currentOnlineUserId).setData({});

    followingReference.document(currentOnlineUserId).collection("userFollowing")
        .document(widget.userProfileId).setData({});

    activityFeedReference.document(widget.userProfileId).collection("feedItems").document(currentOnlineUserId)
    .setData({
      "type": "follow",
      "ownerId": widget.userProfileId,
      "username": currentUser.username,
      "timestamp": DateTime.now(),
      "userProfileImg": currentUser.url,
      "userId": currentOnlineUserId,
    });
  }

  createButtonTitleAndFunction({String title, Function performFunction,}){
    return Container(
      padding: EdgeInsets.only(top: 3.0),
      child: FlatButton(
          onPressed: performFunction,
          child: Container(
            width: 235.0,
            height: 26.0,
            child: Text(title, style: TextStyle(
              color: following ? Colors.grey : Colors.white70,
              fontWeight: FontWeight.bold,
            ),),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: following ? Colors.black : Colors.white70,
              border: Border.all(color: following ? Colors.grey : Colors.white70),
              borderRadius: BorderRadius.circular(6.0),
            ),
      )),
    );
  }

  editUserProfile(){
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(currentOnlineUserId: currentOnlineUserId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: "Profile"),
      body: ListView(
        children: <Widget>[
          createProfileTopVIew(),
          Divider(),
          createListAndGridPostOrientation(),
          Divider(height: 0.0,),
          displayProfilePost(),
        ],
      ),
    );
  }
  displayProfilePost(){
    if(loading){
      return circularProgress();
    }
    else if(postsList.isEmpty){
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.all(30.0),
               child: Icon(Icons.create_new_folder, color: Colors.grey,size: 200.0,),

            ),
            Padding(
                padding: EdgeInsets.only(top: 20.0),
            child: Text(
              "No Post",
              style: TextStyle(
                color: Colors.red,
                fontSize: 40.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            )
          ],
        ),
      );
    }
    else if(postOrientation == "grid"){
      List<GridTile> gridTilesList = [];
      postsList.forEach((eachPost) { 
        gridTilesList.add(GridTile(child: PostTile(eachPost)));
      });
        return GridView.count(crossAxisCount: 3,
        childAspectRatio: 1.0,
          mainAxisSpacing: 1.5,
          crossAxisSpacing: 1.5,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: gridTilesList,
        );
    }
    else if(postOrientation == "list"){
      return Column(
        children: postsList,
      );
    }
    
  }
  getAllProfilePosts() async {
    setState(() {
      loading = true;
    });
    QuerySnapshot querySnapshot = await postsReference.document(widget.userProfileId).collection("usersPosts").orderBy("timestamp", descending: true).getDocuments();
    setState(() {
      loading = false;
      countPost = querySnapshot.documents.length;
      postsList = querySnapshot.documents.map((documentSnapshot) => Post.fromDocument(documentSnapshot)).toList();
    });
  }
  createListAndGridPostOrientation(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setOrientation("grid") ,
          icon: Icon(Icons.grid_on),
          color: postOrientation == "grid" ? Theme.of(context).primaryColor : Colors.grey,
        ),
        IconButton(
          onPressed: () => setOrientation("list") ,
          icon: Icon(Icons.list),
          color: postOrientation == "list" ? Theme.of(context).primaryColor : Colors.grey,
        )
      ],
    );
  }
  setOrientation(String orientation){
    setState(() {
      this.postOrientation = orientation;
    });
  }
}
