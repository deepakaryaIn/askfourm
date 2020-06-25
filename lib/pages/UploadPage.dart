import 'dart:io';
import 'package:Askforum/models/user.dart';
import 'package:Askforum/pages/HomePage.dart';
import 'package:Askforum/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as ImD;

class UploadPage extends StatefulWidget {

  final User gCurrentUser;
  UploadPage({this.gCurrentUser});



  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> with AutomaticKeepAliveClientMixin<UploadPage> {
  File file;
  bool uploading = false;
  String postId = Uuid().v4();

  TextEditingController descriptionTextEditingController = TextEditingController();
  TextEditingController groupTextEditingController = TextEditingController();
  TextEditingController locationTextEditingController = TextEditingController();

  postWithoutImage() {
    //To Implement
  }
  postWithVideo() {
    //To Implement
  }
  postWithAudio() {
 //To Implement
  }

  captureImageWithCamera() async{
    Navigator.pop(context);
    // ignore: deprecated_member_use
    File imageFile = await ImagePicker.pickImage(source: ImageSource.camera,
    maxHeight: 680,
      maxWidth: 970,
    );
    setState(() {
     this.file = imageFile;
    });
  }

  pickImageFromGallery() async {
    Navigator.pop(context);
    // ignore: deprecated_member_use
    File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery,
    );
    setState(() {
      this.file = imageFile;
    });
  }

  takeImage(mContext){
    return showDialog(context: mContext,
    builder: (context){
      return SimpleDialog(
        title: Text("New Post", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        children: <Widget>[
          SimpleDialogOption(
            child: Text("New Post",style: TextStyle(color: Colors.white),),
            onPressed: postWithoutImage,
          ),
          SimpleDialogOption(
            child: Text("Capture Image with Camera",style: TextStyle(color: Colors.white),),
            onPressed: captureImageWithCamera,
          ),
          SimpleDialogOption(
            child: Text("Select Image from Gallery",style: TextStyle(color: Colors.white),),
            onPressed: pickImageFromGallery,
          ),
          SimpleDialogOption(
            child: Text("Post With Video",style: TextStyle(color: Colors.white),),
            onPressed: postWithVideo,
          ),
          SimpleDialogOption(
            child: Text("Post With Audio",style: TextStyle(color: Colors.white),),
            onPressed: postWithAudio,
          ),
          SimpleDialogOption(
            child: Text("Cancel",style: TextStyle(color: Colors.white),),
            onPressed: () {Navigator.pop(context);},
          )
        ],
      );
    }
    );
  }

displayUploadScreen(){
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.note_add, color: Colors.grey, size: 200.0,),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.0)),
              child: Text(
                "New Post",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
              color: Colors.red,
              onPressed: () => takeImage(context),
            ),
          )
        ],
      ),
    );
  }

  clearPostInfo(){
    locationTextEditingController.clear();
    descriptionTextEditingController.clear();
    groupTextEditingController.clear();
    setState(() {
      file = null;
    });
  }

  getUserCurrentLocation() async{
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placeMarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark mPlaceMark = placeMarks[0];
    String completeAddressInfo = '${mPlaceMark.subThoroughfare} ${mPlaceMark.thoroughfare},${mPlaceMark.subLocality} ${mPlaceMark.locality}, ${mPlaceMark.subAdministrativeArea} ${mPlaceMark.administrativeArea},${mPlaceMark.postalCode} ${mPlaceMark.country}';
    String specificAddress = '${mPlaceMark.locality},${mPlaceMark.country}';
    locationTextEditingController.text = specificAddress;
  }

  compressingPhoto() async{
    final tDirectory = await getTemporaryDirectory();
    final path = tDirectory.path;
    ImD.Image mImageFile = ImD.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(ImD.encodeJpg(mImageFile, quality: 60));
    setState(() {
      file = compressedImageFile;
    });
  }

 /* controlUploadWithoutImage() async {
    setState(() {
      uploading = true;
    });

    savePostInfoNew(location: locationTextEditingController.text, description: descriptionTextEditingController.text, group: groupTextEditingController.text );
    locationTextEditingController.clear();
    descriptionTextEditingController.clear();
    groupTextEditingController.clear();

    setState(() {
      uploading = false;
      postId = Uuid().v4();
    });
  }

  savePostInfoNew({ String location, String description, String group})
  {
    postsReference.document(widget.gCurrentUser.id).collection("usersPosts").document(postId).setData(
        {
          "postId": postId,
          "ownerId": widget.gCurrentUser.id,
          "timestamp": DateTime.now(),
          "Likes":{},
          "username": widget.gCurrentUser.username,
          "description": description,
          "location": location,
          "group": group,
        });
  } */

  controlUploadAndSave() async {
    setState(() {
      uploading = true;
    });
    
    await compressingPhoto();

    String downloadUrl = await uploadPhoto(file);

    savePostInfoToFireStore(url: downloadUrl, location: locationTextEditingController.text, description: descriptionTextEditingController.text, group: groupTextEditingController.text );
    locationTextEditingController.clear();
    descriptionTextEditingController.clear();
    groupTextEditingController.clear();

    setState(() {
      file = null;
      uploading = false;
      postId = Uuid().v4();
    });
  }

  savePostInfoToFireStore({String url, String location, String description, String group})
  {
    postsReference.document(widget.gCurrentUser.id).collection("usersPosts").document(postId).setData(
      {
       "postId": postId,
       "ownerId": widget.gCurrentUser.id,
       "timestamp": DateTime.now(),
       "Likes":{},
       "username": widget.gCurrentUser.username,
       "description": description,
       "location": location,
       "group": group,
       "url": url,
      });
  }

  Future<String> uploadPhoto(mImageFile) async {
    StorageUploadTask mStorageUploadTask = storageReference.child("post_$postId.jpg").putFile(mImageFile);
    StorageTaskSnapshot storageTaskSnapshot = await mStorageUploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

 /* displayUploadNew(){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: clearPostInfo),
        title: Text("New Post",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Signatra",
            fontSize: 24.0,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.done_outline, color: Colors.green), onPressed: uploading ? null : () => controlUploadWithoutImage())
        ],
      ) ,
      body: ListView(
        children: <Widget>[
          uploading ? linearProgress() : Text(""),
          Padding(padding: EdgeInsets.only(top: 12.0,)),
          ListTile(
            leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(widget.gCurrentUser.url),),
            title: Container(
              width: 250.0,
              height: 200,
              child: TextField(
                style: TextStyle(
                  color: Colors.white,
                ),
                controller: descriptionTextEditingController,
                decoration: InputDecoration(
                  hintText: "Write Your Question",
                  hintStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          Container(
            width: 220.0,
            height: 110.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35.0)
              ),
              color: Colors.grey,
              icon: Icon(Icons.add_photo_alternate, color: Colors.white,),
              label: Text("Add Image", style: TextStyle(color: Colors.white,
              ),),
              onPressed: () => takeImage(context),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.category,color: Colors.white,size: 36.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(
                  color: Colors.white,
                ),
                controller: groupTextEditingController,
                decoration: InputDecoration(
                  hintText: "Write the Category",
                  hintStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.person_pin,color: Colors.white,size: 36.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(
                  color: Colors.white,
                ),
                controller: locationTextEditingController,
                decoration: InputDecoration(
                  hintText: "Write the Location",
                  hintStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 220.0,
            height: 110.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35.0)
              ),
              color: Colors.green,
              icon: Icon(Icons.location_on, color: Colors.white,),
              label: Text("Get My Current Location", style: TextStyle(color: Colors.white,
              ),),
              onPressed: getUserCurrentLocation,
            ),
          ),
        ],
      ),
    );
  } */

  displayUploadFormScreen(){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: clearPostInfo),
        title: Text("New Post",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Signatra",
            fontSize: 24.0,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.done_outline, color: Colors.green), onPressed: uploading ? null : () => controlUploadAndSave())
        ],
      ) ,
      body: ListView(
        children: <Widget>[
          uploading ? linearProgress() : Text(""),
          Padding(padding: EdgeInsets.only(top: 12.0,)),
          ListTile(
            leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(widget.gCurrentUser.url),),
            title: Container(
              width: 250.0,
              height: 100.0,
              child: TextField(
                style: TextStyle(
                  color: Colors.white,
                ),
                controller: descriptionTextEditingController,
                decoration: InputDecoration(
                  hintText: "Write Your Question",
                  hintStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          Container(
            height: 200.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16/9,
                child: Container(
                  decoration: BoxDecoration(image: DecorationImage(image: FileImage(file), fit: BoxFit.cover)),
                ),
              ),
            ),

          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.category,color: Colors.white,size: 36.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(
                  color: Colors.white,
                ),
                controller: groupTextEditingController,
                decoration: InputDecoration(
                  hintText: "Write the Category",
                  hintStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.person_pin,color: Colors.white,size: 36.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(
                  color: Colors.white,
                ),
                controller: locationTextEditingController,
                decoration: InputDecoration(
                  hintText: "Write the Location",
                  hintStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 220.0,
            height: 110.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35.0)
            ),
              color: Colors.green,
              icon: Icon(Icons.location_on, color: Colors.white,),
              label: Text("Get My Current Location", style: TextStyle(color: Colors.white,
              ),),
              onPressed: getUserCurrentLocation,
            ),
          )
        ],
      ),
    );
  }


  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return file == null ? displayUploadScreen() : displayUploadFormScreen()  ;
  }
}
