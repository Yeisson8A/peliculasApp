import 'package:flutter/material.dart';
import 'package:peliculas_app/providers/movies_provider.dart';
import 'package:peliculas_app/search/movie_search_delegate.dart';
import 'package:peliculas_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
   
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Obtener instancia al provider
    final moviesProvider = Provider.of<MoviesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Películas en cine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined, color: AppTheme.textColor),
            onPressed: () => showSearch(context: context, delegate: MovieSearchDelegate()), 
          )
        ],),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Widget carrusel de tarjetas
            CardSwiper(movies: moviesProvider.onDisplayMovies),
            // Widget slider horizontal
            MovieSlider(movies: moviesProvider.popularMovies, title: 'Populares', onNextPage: () => moviesProvider.getPopularMovies())
          ],
        ),
      )
    );
  }
}