import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:camera/camera.dart';

@immutable
sealed class CameraState extends Equatable
{
  final CameraController? cameraController;
  final String? currentResponse;
  final bool isResponding;

  const CameraState({
    this.cameraController,
    this.currentResponse,
    this.isResponding=false
});

  @override
  // TODO: implement props
  List<Object?> get props => [cameraController,currentResponse,isResponding];
}


final class CameraInitial extends CameraState{}


class CameraReady extends CameraState
{
  const CameraReady({
    required super.cameraController,
    super.currentResponse,
    super.isResponding
});

  @override
  // TODO: implement props
  List<Object?> get props => [cameraController,currentResponse,isResponding];
}

class CameraLoading extends CameraState
{
  const CameraLoading({
    super.cameraController,
    super.currentResponse,
    super.isResponding=true
});

  @override
  // TODO: implement props
  List<Object?> get props => [cameraController,currentResponse,isResponding];
}

class CameraError extends CameraState
{
  final String error;

  const CameraError({
    required this.error,
    super.cameraController,
    super.currentResponse,
    super.isResponding
});

  @override
  // TODO: implement props
  List<Object?> get props => [error,cameraController,currentResponse,isResponding];
}



