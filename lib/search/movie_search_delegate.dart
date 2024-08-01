import 'package:flutter/material.dart';
import 'package:peliculas_app/providers/movies_provider.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';

class MovieSearchDelegate extends SearchDelegate {
  // Texto del buscador
  @override
  String get searchFieldLabel => 'Buscar película';

  // Opciones que aparecerán en el buscador (Extremo derecho)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = ''
      )
    ];
  }

  // Opciones que aparecerán en el buscador (Extremo izquierdo)
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null) 
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    throw UnimplementedError();
  }

  // Widget que se utilizará cuando no haya datos
  Widget _emptyContainer() {
    return Container(
        child: const Center(
          child: Icon(Icons.movie_creation_outlined, color: Colors.black38, size: 130),
        )
    );
  }

  // Listado de datos a mostrar como sugerencias del buscador
  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _emptyContainer();
    }
    final moviesProvider = Provider.of<MoviesProvider>(context, listen: false);
    moviesProvider.getSuggestionsByQuery(query);

    // Llamar a un stream que va a estar escuchando
    return StreamBuilder(
      stream: moviesProvider.suggestionStream,
      builder: ( _, AsyncSnapshot<List<Movie>> snapshot) {
        // En caso de que no tenga datos
        if (!snapshot.hasData) return _emptyContainer();

        // Obtener datos del future
        final List<Movie> movies = snapshot.data!;
        // Cuando ya se tiene datos
        return ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) => _MovieItem(movies[index]),
        );
      },
    );
  }
}

class _MovieItem extends StatelessWidget {
  final Movie movie;
  const _MovieItem(this.movie);

  @override
  Widget build(BuildContext context) {
    movie.heroId = 'search-${movie.id}';
    return ListTile(
      title: Text(movie.title),
      subtitle: Text(movie.originalTitle),
      leading: Hero(
        tag: movie.heroId!,
        child: FadeInImage(
          placeholder: const AssetImage('assets/no-image.jpg'), 
          image: NetworkImage(movie.fullPosterImg),
          width: 50,
          fit: BoxFit.contain,
        ),
      ),
      onTap: () => Navigator.pushNamed(context, 'details', arguments: movie)
    );
  }
}