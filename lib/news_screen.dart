import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>>? _newsArticles;
  final List<String> _categories = [
    'all',
    'national',
    'business',
    'sports',
    'world',
    'politics',
    'technology',
    'startup',
    'entertainment',
    'miscellaneous',
    'hatke',
    'science',
    'automobile',
  ];
  String _currentCategory = 'national';
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPageIndex = 0;
  late SharedPreferences _prefs;
  List<String> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    initSharedPreferences();
    fetchNews();
  }

  Future<void> initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _bookmarks = _prefs.getStringList('bookmarks') ?? [];
  }

  Future<void> fetchNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await http.get(
      Uri.parse('https://inshortsapi.vercel.app/news?category=$_currentCategory'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedData = json.decode(response.body);
      final List<dynamic> articles = decodedData['data'];

      if (articles.isNotEmpty) {
        setState(() {
          _newsArticles = articles.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No news articles found in $_currentCategory category.';
        });
      }
    } else {
      print('Error fetching news: ${response.statusCode}');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch news. Please try again later.';
      });
    }
  }

  Future<void> toggleBookmark(int index) async {
    if (_newsArticles != null && index >= 0 && index < _newsArticles!.length) {
      final String articleTitle = _newsArticles![index]['title'];
      if (_bookmarks.contains(articleTitle)) {
        _bookmarks.remove(articleTitle);
      } else {
        _bookmarks.add(articleTitle);
      }
      await _prefs.setStringList('bookmarks', _bookmarks);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News'),
        backgroundColor: Colors.indigo, // Custom app bar color
        elevation: 0, // No shadow
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark),
            onPressed: () {
              Navigator.pushNamed(context, '/bookmarks');
            },
          ),
        ],
      ),
      backgroundColor: Colors.blueGrey[50], // Set a custom background color
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 10), // Add spacing from above
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentCategory = _categories[index];
                    });
                    fetchNews();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _currentCategory == _categories[index] ? Colors.indigo : Colors.transparent,
                      borderRadius: BorderRadius.circular(20), // Add border radius
                    ),
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: _currentCategory == _categories[index] ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _newsArticles != null && _newsArticles!.isNotEmpty
                ? PageView.builder(
              itemCount: _newsArticles!.length,
              controller: PageController(initialPage: _currentPageIndex),
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final article = _newsArticles![index];
                final bool isBookmarked = _bookmarks.contains(article['title']);
                return AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? Colors.indigo : Colors.grey,
                            ),
                            onPressed: () => toggleBookmark(index),
                          ),
                          Text(
                            _currentCategory.toUpperCase(),
                            style: TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (article['image'] != null)
                        CachedNetworkImage(
                          imageUrl: article['image'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        ),
                      if (article['video'] != null)
                        Chewie(
                          controller: ChewieController(
                            videoPlayerController: VideoPlayerController.network(
                              article['video'],
                            ),
                            autoPlay: true,
                            looping: true,
                          ),
                        ),
                      SizedBox(height: 8),
                      Text(
                        article['title'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        article['content'],
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            )
                : Center(child: Text('No news articles found in $_currentCategory category.')),
          ),
        ],
      ),
    );
  }
}
