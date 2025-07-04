part of 'download_model_bloc.dart';

sealed class DownloadModelEvent extends Equatable{
  const DownloadModelEvent();

  @override
  List<Object> get props => [];
}

class CheckModelExists extends DownloadModelEvent{}

class StartDownload extends DownloadModelEvent{}

class DownloadProgressChanged extends DownloadModelEvent{
  final double progress;
  const DownloadProgressChanged(this.progress);

  @override
  List<Object> get props=>[progress];
}