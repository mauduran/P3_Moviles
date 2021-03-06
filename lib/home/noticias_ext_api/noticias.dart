import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_login/home/noticias_ext_api/bloc/api_news_bloc.dart';
import 'package:google_login/home/noticias_firebase/bloc/my_news_bloc.dart'
    as BLOC;
import 'package:google_login/models/new.dart';

import 'item_noticia.dart';

class Noticias extends StatefulWidget {
  const Noticias({Key key}) : super(key: key);

  @override
  _NoticiasState createState() => _NoticiasState();
}

class _NoticiasState extends State<Noticias> {
  ApiNewsBloc _bloc;
  String _currentQuery = "";
  final _cFirestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        _bloc = ApiNewsBloc();
        _bloc..add(RequestApiNewsEvent(query: this._currentQuery));
        return _bloc;
      },
      child: Container(
          child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                hintText: "Search news!",
                fillColor: Colors.white,
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.blue[600],
                ),
                contentPadding: EdgeInsets.only(left: 8.0, top: 16.0),
              ),
              onSubmitted: (String query) {
                _bloc.add(RequestApiNewsEvent(query: query));
              },
            ),
          ),
          BlocConsumer<ApiNewsBloc, ApiNewsState>(listener: (context, state) {
            if (state is ErrorMessageState) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(state.errorMsg),
                  ),
                );
            } else if (state is LoadedSavedNewsState) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content:
                        Text("Sin conexion. Mostrando noticias anteriores"),
                  ),
                );
            }
          }, builder: (context, state) {
            if (state is LoadedNewsState) {
              return NewsFound(
                noticiasList: state.noticiasList,
                function: _saveNoticias,
              );
            } else if (state is LoadedSavedNewsState) {
              return NewsFound(
                noticiasList: state.noticiasList,
                function: _saveNoticias,
              );
            } else if (state is ErrorMessageState) {
              return Center(
                child: Text("Algo salio mal", style: TextStyle(fontSize: 32)),
              );
            }
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                ],
              ),
            );
          }),
        ],
      )),
    );
  }

  fetchNews(String query) {
    _bloc.add(RequestApiNewsEvent(query: query));
  }

  Future<void> _saveNoticias(
    New noticia,
  ) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.mobile &&
          connectivityResult != ConnectivityResult.wifi)
        throw Exception("Offline");
      await _cFirestore.collection("noticias").add(noticia.toJson());
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Noticia guardada exitosamente!"),
          ),
        );
      BlocProvider.of<BLOC.MyNewsBloc>(context).add(BLOC.RequestAllNewsEvent());
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("La noticia no se pudo guardar!"),
          ),
        );
    }
  }
}

class NewsFound extends StatelessWidget {
  final List<New> noticiasList;
  final Function function;
  const NewsFound({
    @required this.noticiasList,
    Key key,
    @required this.function,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: noticiasList.length == 0
          ? Center(
              child: Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Text(
                "No se encontraron noticias",
                style: TextStyle(fontSize: 40),
                textAlign: TextAlign.center,
              ),
            ))
          : ListView.builder(
              itemCount: noticiasList.length,
              itemBuilder: (context, index) {
                return ItemNoticia(
                  noticia: noticiasList[index],
                  fromApi: true,
                  saveNew: () {
                    function(noticiasList[index]);
                  },
                );
              },
            ),
    );
  }
}
