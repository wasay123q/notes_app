import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../models/note.dart';
import '../models/category.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load notes and categories when the screen initializes
    Provider.of<NotesProvider>(context, listen: false).loadCategories();
    Provider.of<NotesProvider>(context, listen: false).loadNotes();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticky'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // TODO: Implement drawer
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_agenda_outlined),
            onPressed: () {
              // TODO: Implement view toggle
            },
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              _showCategoryDialog(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[800],
              child: IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  // TODO: Implement profile button
                },
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search your notes',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
        ),
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, child) {
          if (notesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notesProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    notesProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      notesProvider.loadCategories();
                      notesProvider.loadNotes();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Filter notes based on search query
          final filteredNotes =
              notesProvider.notes.where((note) {
                final titleLower = note.title.toLowerCase();
                final contentLower = note.content.toLowerCase();
                final searchQueryLower = _searchQuery.toLowerCase();
                return titleLower.contains(searchQueryLower) ||
                    contentLower.contains(searchQueryLower);
              }).toList();

          return Column(
            children: [
              _buildCategoryFilter(notesProvider),
              Expanded(
                child: _buildNotesList(filteredNotes, notesProvider.categories),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(context),
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildCategoryFilter(NotesProvider notesProvider) {
    if (notesProvider.categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No categories yet. Add one by tapping the category icon in the app bar!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: notesProvider.categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: const Text('Main'),
                selected: notesProvider.selectedCategoryId == null,
                onSelected: (selected) {
                  notesProvider.setSelectedCategory(null);
                },
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color:
                      notesProvider.selectedCategoryId == null
                          ? Colors.black
                          : Colors.white,
                ),
              ),
            );
          }
          final category = notesProvider.categories[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(category.name),
              selected: notesProvider.selectedCategoryId == category.id,
              onSelected: (selected) {
                notesProvider.setSelectedCategory(category.id);
              },
              selectedColor: Color(
                int.parse(category.color.replaceAll('#', '0xFF')),
              ),
              labelStyle: TextStyle(
                color:
                    notesProvider.selectedCategoryId == category.id
                        ? Colors.black
                        : Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes, List<Category> categories) {
    if (notes.isEmpty) {
      return const Center(child: Text('No notes found.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final category = categories.firstWhere(
          (c) => c.id == note.categoryId,
          orElse: () => Category(name: 'Unknown', color: '#000000'),
        );

        // Format date and time
        final DateFormat formatter = DateFormat('MMMM d yyyy HH:mm');
        final String formattedDate = formatter.format(note.createdAt);

        return AnimationConfiguration.staggeredGrid(
          position: index,
          duration: const Duration(milliseconds: 375),
          columnCount: 2, // Assuming 2 columns in the grid
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: InkWell(
                onTap: () => _showNoteDialog(context, note: note),
                child: Card(
                  color: Color(
                    int.parse(category.color.replaceAll('#', '0xFF')),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getTextColor(
                                    Color(
                                      int.parse(
                                        category.color.replaceAll('#', '0xFF'),
                                      ),
                                    ),
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // IconButton(
                            //   icon: const Icon(Icons.more_vert, color: Colors.black),
                            //   onPressed: () {
                            //     // TODO: Implement more options like delete
                            //   },
                            // ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            note.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getTextColor(
                                Color(
                                  int.parse(
                                    category.color.replaceAll('#', '0xFF'),
                                  ),
                                ),
                              ).withOpacity(0.9),
                            ),
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getTextColor(
                              Color(
                                int.parse(
                                  category.color.replaceAll('#', '0xFF'),
                                ),
                              ),
                            ).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getTextColor(Color backgroundColor) {
    // Calculate the luminance of the background color
    final double luminance = backgroundColor.computeLuminance();
    // Return black text for light backgrounds and white text for dark backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _showNoteDialog(BuildContext context, {Note? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    int? selectedCategoryId =
        note?.categoryId ?? notesProvider.categories.firstOrNull?.id;

    if (notesProvider.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a category first!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              note == null ? 'New Note' : 'Edit Note',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: contentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Content',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  dropdownColor:
                      Theme.of(
                        context,
                      ).cardColor, // Darker background for dropdown
                  style: const TextStyle(
                    color: Colors.white,
                  ), // Text color for selected item
                  items:
                      notesProvider.categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            category.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    selectedCategoryId = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (titleController.text.isEmpty ||
                      contentController.text.isEmpty ||
                      selectedCategoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  final newNote = Note(
                    id: note?.id,
                    title: titleController.text,
                    content: contentController.text,
                    categoryId: selectedCategoryId!,
                    createdAt: note?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  if (note == null) {
                    notesProvider.addNote(newNote);
                  } else {
                    notesProvider.updateNote(newNote);
                  }

                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final colorController = TextEditingController(text: '#000000');
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'New Category',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: colorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Color (hex)',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: '#RRGGBB',
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a category name!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  if (!colorController.text.startsWith('#') ||
                      colorController.text.length != 7) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid hex color (e.g., #FF0000)!',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  final category = Category(
                    name: nameController.text,
                    color: colorController.text,
                  );

                  notesProvider.addCategory(category);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}
