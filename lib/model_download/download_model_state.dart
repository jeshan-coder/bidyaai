part of 'download_model_bloc.dart';

/*
state related to checking and downloading model from hugging face
 */
sealed class DownloadModelState extends Equatable{
  const DownloadModelState();

  @override
  List<Object> get props => [];
}

class DownloadModelInitial extends DownloadModelState {}

class DownloadInprogress extends DownloadModelState
{
  final double progress;
  const DownloadInprogress(this.progress);

  @override
  // TODO: implement props
  List<Object> get props =>[progress];
}

class DownloadSuccess extends DownloadModelState
{
  final String filePath;
  const DownloadSuccess(this.filePath);

  @override
  // TODO: implement props
  List<Object> get props =>[filePath];

}


class ModelAlreadyExists extends DownloadModelState
{
  final String filePath;
  const ModelAlreadyExists(this.filePath);

  @override
  // TODO: implement props
  List<Object> get props =>[filePath];
}

class DownloadFailure extends DownloadModelState
{
  final String error;
  const DownloadFailure(this.error);

  @override
  // TODO: implement props
  List<Object> get props =>[error];
}



