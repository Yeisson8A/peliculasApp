import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:peliculas_app/helpers/debouncer.dart';
import 'package:peliculas_app/models/search_response.dart';
import '../models/models.dart';

class MoviesProvider extends ChangeNotifier {
  final String _baseUrl = 'api.themoviedb.org';
  final String _apiKey = '41e73c87ecc266dec8c495ab0ab2f8ab';
  final String _language = 'es-ES';
  int _popularPage = 0;
  // Listado de peliculas (CardSwiper)
  List<Movie> onDisplayMovies = [];
  // Listado de peliculas populares (MovieSlider)
  List<Movie> popularMovies = [];
  // Mapas para mantener datos de peliculas en memoria
  Map<int, List<Cast>> movieCast = {};
  Map<String, List<Movie>> moviesSearch = {};
  // Definir debouncer
  final debouncer = Debouncer(duration: const Duration(milliseconds: 500));
  // Stream controller para sugerencias de peliculas en el buscador
  final StreamController<List<Movie>> _suggestionStreamController = StreamController.broadcast();
  // Stream para sugerencias de peliculas en el buscador
  Stream<List<Movie>> get suggestionStream => _suggestionStreamController.stream;

  MoviesProvider() {
    getOnDisplayMovies();
    getPopularMovies();
  }

  Future<String> _getJsonData(String endpoint, [int page = 1]) async {
    final url = Uri.https(_baseUrl, endpoint, {
        'api_key': _apiKey,
        'language': _language,
        'page': '$page'
    });
    final response = await http.get(url);
    return response.body;
  }
  
  // Método para obtener listado de peliculas (Componente superior)
  getOnDisplayMovies() async {
    final jsonData = await _getJsonData('3/movie/now_playing');
    final nowPlayingResponse = NowPlayingResponse.fromRawJson(jsonData);
    onDisplayMovies = nowPlayingResponse.results;
    // Indica que las propiedades en el provider cambiaron, para redibujar
    notifyListeners();
  }

  // Método para obtener listado de peliculas populares
  getPopularMovies() async {
    _popularPage++;
    final jsonData = await _getJsonData('3/movie/popular', _popularPage);
    final popularResponse = PopularResponse.fromRawJson(jsonData);
    popularMovies = [...popularMovies, ...popularResponse.results];
    // Indica que las propiedades en el provider cambiaron, para redibujar
    notifyListeners();
  }

  // Método para obtener listado de actores de una pelicula especifica
  Future<List<Cast>> getMovieCast(int movieId) async {
    // Se valida si la información de esa pelicula ya está cargada en la variable y no llamar a la API nuevamente
    if (movieCast.containsKey(movieId)) return movieCast[movieId]!;
    // Hacer petición a la API
    final jsonData = await _getJsonData('3/movie/$movieId/credits');
    final creditsResponse = CreditsResponse.fromRawJson(jsonData);
    // Guardar en un mapa el resultado
    // Key => Id de la pelicula
    // Value => Listado de actores
    movieCast[movieId] = creditsResponse.cast;
    return creditsResponse.cast;
  }

  // Método para obtener listado de peliculas con base en una búsqueda
  Future<List<Movie>> searchMovies(String query) async {
    // Se valida si el listado de peliculas para una búsqueda ya está cargada en la variable y no llamar a la API nuevamente
    if (moviesSearch.containsKey(query)) return moviesSearch[query]!;
    // Hacer petición a la API
    final url = Uri.https(_baseUrl, '3/search/movie', {
        'api_key': _apiKey,
        'language': _language,
        'query': query
    });
    final response = await http.get(url);
    final searchResponse = SearchResponse.fromRawJson(response.body);
    // Guardar en un mapa el resultado
    // Key => Query búsqueda
    // Value => Listado de peliculas
    moviesSearch[query] = searchResponse.results;
    return searchResponse.results;
  }

  void getSuggestionsByQuery(String searchTerm) {
    debouncer.value = '';
    // Pasados 500 milisegundos y que el valor del buscador se asigno se hace la petición
    debouncer.onValue = (value) async {
      // Llamar método para obtener listado de peliculas con base en una búsqueda
      final results = await searchMovies(value);
      // Agregar resultado de peliculas al stream
      _suggestionStreamController.add(results);
    };
    // Esperar 300 milisegundos para asignar el valor del buscador
    final timer = Timer.periodic(const Duration(milliseconds: 300), ( _ ) {
      debouncer.value = searchTerm;
    });
    // Pasados 1 milisegundo más se cancela la espera del timer
    Future.delayed(const Duration(milliseconds: 301)).then(( _ ) => timer.cancel());
  }
}