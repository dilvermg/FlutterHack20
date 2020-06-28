import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:hack20/footer.dart';
import 'package:hack20/picture_picker.dart';
import 'package:hack20/models/result.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ImagePicker _imagePicker = ImagePicker();
  File _selectedPicture;
  Result _result;

  Future pickImage() async {
    PickedFile pickedFile =
        await _imagePicker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      setState(() {
        _selectedPicture = file;
      });
      identifyImage(file);
    }
  }

  void cropImage(File image) async {
    File croppedImage = await ImageCropper.cropImage(
      cropStyle: CropStyle.rectangle,
      sourcePath: image.path,
      aspectRatio: CropAspectRatio(ratioX: 3, ratioY: 2),
      maxWidth: 512,
      maxHeight: 512,
    );

    if (croppedImage != null && this.mounted) {
      setState(() {
        this._selectedPicture = croppedImage;
        identifyImage(croppedImage);
      });
    }
  }

  Future identifyImage(File file) async {
    String res = await Tflite.loadModel(
      model: "assets/tflite/model_unquant.tflite",
      labels: "assets/tflite/labels.txt",
    );

    List<dynamic> recognitions = await Tflite.runModelOnImage(
      path: file.path,
      numResults: 1,
      imageMean: 128,
      imageStd: 128,
    );

    if (recognitions.isNotEmpty) {
      print(recognitions);
      setState(() {
        _result = Result.fromMap(recognitions.first);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[300],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green[900],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Recycling",
              style: Theme.of(context)
                  .textTheme
                  .headline4
                  .copyWith(color: Colors.black, fontWeight: FontWeight.w700),
              textAlign: TextAlign.start,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 2.0),
              child: Text(
                "Select a picture to start!",
                textAlign: TextAlign.start,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 36.0),
              child: PicturePicker(
                  imageFile: _selectedPicture,
                  shape: BoxShape.rectangle,
                  width: MediaQuery.of(context).size.width - 56,
                  onTap: () => pickImage()),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 28.0, bottom: 12),
              child: Divider(),
            ),
            if (_result != null) buildResult(context),
            Spacer(),
            Footer(),
          ],
        ),
      ),
    );
  }

  Padding buildResult(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: <Widget>[
          Card(
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _result.label,
                          style: Theme.of(context).textTheme.headline5.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                        ),
                        Text(
                          '${(_result.confidence * 100).toStringAsFixed(2)} %',
                          style: Theme.of(context).textTheme.headline6.copyWith(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w400,
                                height: 1,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
