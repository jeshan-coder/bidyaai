

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ModelRepository
{
  final Dio _dio=Dio();

  static const String _modelFileName= 'gemma-3n-E4B-it-int4.task';

  static const String _modelUrl= 'https://drive.google.com/uc?export=download&id=1g8G_EzgU4B37yBZBgAWda4XZfsc2zBfc';

  Future<String> getModelFilePath() async {

    final directory= await getApplicationDocumentsDirectory();
    return '${directory.path}/$_modelFileName';
  }


  Future<bool> checkIfModelExists() async {
    final filePath= await getModelFilePath();
    return File(filePath).exists();
  }


  Future<String> downloadModel(Function(double) onProgress) async{
    final filePath= await getModelFilePath();
    try{
      await _dio.download(_modelUrl,filePath,onReceiveProgress: (received,total){
        if(total != -1)
          {
            double progress=received/total;
            onProgress(progress);
          }
      });
      return filePath;
    } on DioException catch(e){
      final file=File(filePath);

      if(await file.exists()){
        await file.delete();
      }

      throw Exception("Failed to download model.please check network connection and try again");
    }
  }
}