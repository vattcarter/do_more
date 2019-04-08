import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../utils.dart' show kBlueGradient, getImageThumbnailPath;
import '../blocs/event_bloc.dart';
import '../models/task_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/fractionally_screen_sized_box.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/task_list_tile.dart';

class EventScreen extends StatefulWidget {
  /// The name of the event this screenn is showing.
  final String eventName;

  EventScreen({
    @required this.eventName,
  });

  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen>
    with SingleTickerProviderStateMixin {
  EventBloc bloc;
  TabController _tabController;
  initState() {
    super.initState();
    bloc = EventBloc(eventName: widget.eventName);
    bloc.fetchTasks();
    bloc.fetchImagesPaths();
    _tabController = TabController(vsync: this, length: 2);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          buildTasksListView(),
          buildMediaView(),
        ],
      ),
    );
  }

  Widget buildAppBar() {
    return CustomAppBar(
      title: widget.eventName,
      bottom: TabBar(
        controller: _tabController,
        tabs: <Tab>[
          Tab(
            text: 'Tasks',
          ),
          Tab(
            text: 'Media',
          ),
        ],
      ),
    );
  }

  Widget buildTasksListView() {
    return StreamBuilder(
      stream: bloc.eventTasks,
      builder: (BuildContext context, AsyncSnapshot<List<TaskModel>> snap) {
        if (!snap.hasData) {
          return Center(
            child: LoadingIndicator(),
          );
        }

        return ListView(
          padding: EdgeInsets.only(top: 15),
          children: snap.data
              .map((task) => Container(
                    child: TaskListTile(
                      task: task,
                      hideEventButton: true,
                      onDone: () => bloc.markTaskAsDone(task),
                      onEditPressed: () {
                        // Include the id of the task to be edited in the route.
                        Navigator.of(context).pushNamed('editTask/${task.id}');
                      },
                    ),
                    padding: EdgeInsets.only(bottom: 12),
                  ))
              .toList()
                ..add(Container(height: 70)),
        );
      },
    );
  }

  // TODO: refactor this.
  Widget buildMediaView() {
    return StreamBuilder(
      stream: bloc.imagesPaths,
      builder: (BuildContext context, AsyncSnapshot<List<String>> listSnap) {
        if (!listSnap.hasData) {
          return Center(
            child: LoadingIndicator(),
          );
        }

        return GridView.builder(
          itemCount: listSnap.data.length + 1,
          padding: EdgeInsets.all(10.0),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  gradient: kBlueGradient,
                ),
              );
            }
            final imagePath = listSnap.data[index - 1];
            bloc.fetchThumbnail(imagePath);
            return StreamBuilder(
              stream: bloc.thumbnails,
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, Future<File>>> thumbailsCacheSnap) {
                if (!thumbailsCacheSnap.hasData) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.grey,
                    ),
                  );
                }
                return FutureBuilder(
                  future:
                      thumbailsCacheSnap.data[getImageThumbnailPath(imagePath)],
                  builder: (BuildContext context,
                      AsyncSnapshot<File> thumbnailFileSnap) {
                    if (!thumbnailFileSnap.hasData) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: Colors.grey,
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(thumbnailFileSnap.data),
                    );
                  },
                );
              },
            );
          },
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
        );
      },
    );
  }

  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}
