import 'package:flutter/material.dart';

import 'modal_bottom_route.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MaterialButton(
              color: Colors.blue,
              child: const Text("Let's Route"),
              onPressed: () async {
                Widget nextPage = Scaffold(
                  appBar: AppBar(
                      title: const Text(
                    "FoundationRoute",
                  )),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("旧路由"),
                        MaterialButton(
                          color: Colors.blue,
                          child: const Text("Push 新路由"),
                          onPressed: () async {
                            Navigator.push(context, IOSPageRoute(
                              builder: (context) {
                                return Scaffold(
                                  body: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.grey[500],
                                        borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(7),
                                            topRight: Radius.circular(7))),
                                    child: const Center(
                                      child: Text("新路由"),
                                    ),
                                  ),
                                );
                              },
                            ));
                          },
                        )
                      ],
                    ),
                  ),
                );

                Navigator.push(
                    context, FoundationRoute(builder: (context) => nextPage));
              },
            )
          ],
        ),
      ),
    );
  }
}
