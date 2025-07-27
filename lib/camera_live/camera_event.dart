import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';


@immutable
sealed class CameraEvent extends Equatable
{
  const CameraEvent();

  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class InitializeCamera extends CameraEvent
{}


class CaptureAndSendMessage extends CameraEvent
{
  final String message;
  final Uint8List imageBytes;

  const CaptureAndSendMessage({required this.message,required this.imageBytes});

  @override
  // TODO: implement props
  List<Object?> get props => [message,imageBytes];
}

class ClearResponse extends CameraEvent{}
