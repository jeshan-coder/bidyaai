import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'model_repository.dart';

part 'download_model_event.dart';
part 'download_model_state.dart';

class DownloadModelBloc extends Bloc<DownloadModelEvent, DownloadModelState> {
  final ModelRepository _modelRepository;

  DownloadModelBloc(this._modelRepository) : super(DownloadModelInitial()) {
    // on<DownloadModelEvent>((event, emit) {
    // TODO: implement event handler
    // });
    on<CheckModelExists>(_onCheckModelExists);
    on<StartDownload>(_onStartDownload);
    on<DownloadProgressChanged>((event, emit) {
      emit(DownloadInprogress(event.progress));
    });
  }

  Future<void> _onCheckModelExists(
    CheckModelExists event,
    Emitter<DownloadModelState> emit,
  ) async {
    try {
      final filePath = await _modelRepository.getModelFilePath();
      final fileExists = await _modelRepository.checkIfModelExists();

      if (fileExists) {
        emit(ModelAlreadyExists(filePath));
        print("file exists $filePath");
      } else {
        add(StartDownload());
      }
    } catch (e) {
      print("Download failure");
      emit(DownloadFailure(e.toString()));
    }
  }

  Future<void> _onStartDownload(
    StartDownload event,
    Emitter<DownloadModelState> emit,
  ) async {
    emit(const DownloadInprogress(0.0));

    try {
      final filePath = await _modelRepository.downloadModel((progress) {
        add(DownloadProgressChanged(progress));
      });
      emit(DownloadSuccess(filePath));
    } catch (e) {
      print("Exception occured on download $e");
      emit(DownloadFailure(e.toString()));
    }
  }
}
