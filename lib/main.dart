import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

import 'dart:async';

void main() {
  runApp(MyApp());
}

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gallery App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _images = [];
  bool _loading = true;
  late TextEditingController _searchController;
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _debouncer = Debouncer(delay: Duration(milliseconds: 500));
    _fetchImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchImages({String? query}) async {
    setState(() {
      _loading = true;
    });

    final response = await http.get(Uri.parse(
        'https://pixabay.com/api/?key=43680036-e7a3d4d52964b2e1c12444ddb&per_page=50${query != null ? '&q=$query' : ''}'));
    if (response.statusCode == 200) {
      setState(() {
        _images = json.decode(response.body)['hits'];
        _loading = false;
      });
    }
  }

  void _onSearchTextChanged(String text) {
    _debouncer.run(() {
      _fetchImages(query: text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
              ),
              onChanged: _onSearchTextChanged,
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : StaggeredGridView.countBuilder(
                    crossAxisCount: MediaQuery.of(context).size.width ~/ 200,
                    itemCount: _images.length,
                    itemBuilder: (BuildContext context, int index) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImage(imageUrl: _images[index]['largeImageURL']),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          CachedNetworkImage(
                            imageUrl: _images[index]['previewURL'],
                            placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          ),
                          Text('Likes: ${_images[index]['likes']}'),
                          Text('Views: ${_images[index]['views']}'),
                        ],
                      ),
                    ),
                    staggeredTileBuilder: (int index) => StaggeredTile.fit(1),
                  ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered,
          ),
        ),
      ),
    );
  }
}
