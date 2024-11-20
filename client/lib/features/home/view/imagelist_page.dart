import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:social_heart/core/theme/app_pallete.dart';

class ImagelistPage extends StatefulWidget {
  final List<String>? imageUrls;
  const ImagelistPage({
    super.key,
    required this.imageUrls,
  });

  @override
  State<ImagelistPage> createState() => _ImagelistPageState();
}

class _ImagelistPageState extends State<ImagelistPage> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < (widget.imageUrls as List<String>).length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        width: MediaQuery.of(context).size.width * 0.9,
        child: DottedBorder(
          color: Pallete.primaryBorder,
          strokeWidth: 2,
          dashPattern: const [4, 3],
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const Center(
              child: Text(
                "No images found",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls == null ||
        (widget.imageUrls as List<String>).isEmpty) {
      return Scaffold(
        backgroundColor: Pallete.white,
        appBar: AppBar(
          backgroundColor: Pallete.white,
        ),
        body: _buildEmptyState(),
      );
    } else {
      return Scaffold(
        backgroundColor: Pallete.white,
        appBar: AppBar(
          backgroundColor: Pallete.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: (widget.imageUrls as List<String>).length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          (widget.imageUrls as List<String>)[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Left and Right touch areas for navigation
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _previousPage,
                        child: Container(color: Pallete.transparent),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _nextPage,
                        child: Container(color: Pallete.transparent),
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontal Page indicators at the top
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: List.generate(
                      (widget.imageUrls as List<String>).length,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.5),
                            color: _currentPage == index
                                ? Pallete.white
                                : Pallete.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
