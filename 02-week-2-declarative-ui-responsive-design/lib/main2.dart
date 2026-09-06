import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

const double kWideBreakpoint = 600;
void main() => runApp(const DashboardApp());

// class DashboardApp extends StatelessWidget {
//   const DashboardApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
//       darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.indigo),
//       themeMode: ThemeMode.system,
//       home: const DashboardPage(),
//     );
//   }
// }

//info card untuk reusble
class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.value, super.key});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      // themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      // themeMode: ThemeMode.system,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

// class DashboardPage extends StatelessWidget {
//   const DashboardPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Student Dashboard')),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           final columns = constraints.maxWidth >= 700 ? 2 : 1;
//           return GridView.count(
//             padding: const EdgeInsets.all(16),
//             crossAxisCount: columns,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//             childAspectRatio: 2.6,
//             children: const [
//               DashboardCard(title: 'Assignments', value: '8'),
//               DashboardCard(title: 'Attendance', value: '92%'),
//               DashboardCard(title: 'Portfolio', value: 'Ready'),
//               DashboardCard(title: 'Current week', value: '02'),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          ),
          Semantics(
            label: 'Toggle dark mode',
            child: CupertinoSwitch(value: isDark, onChanged: onDarkChanged),
          ),
          const SizedBox(width: 12),
        ],
      ),

      // body: LayoutBuilder(
      //   builder: (context, constraints) {
      //     final columns = constraints.maxWidth >= 600 ? 2 : 1;

      //     return Semantics(
      //       //add semantics
      //       label: 'Dashboard with $columns columns',

      //       child: GridView.count(
      //         //return>child
      //         padding: const EdgeInsets.all(16),
      //         crossAxisCount: columns,
      //         crossAxisSpacing: 16,
      //         mainAxisSpacing: 16,
      //         childAspectRatio: 2.6,
      //         children: const [
      //           DashboardCard(title: 'Assignments', value: '8'),
      //           DashboardCard(title: 'Attendance', value: '92%'),
      //           DashboardCard(title: 'Portfolio', value: 'Ready'),
      //           DashboardCard(title: 'Current week', value: '02'),
      //         ],
      //       ),
      //     );
      //   },
      // ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= kWideBreakpoint ? 2 : 1;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Muhammad Anka Reza',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Academic Overview',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Semantics(
                  label: 'Dashboard with $columns columns',
                  child: GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.6,
                    children: const [
                      InfoCard(title: 'Assignments', value: '8'),
                      InfoCard(title: 'Attendance', value: '92%'),
                      InfoCard(title: 'Portfolio', value: 'Ready'),
                      InfoCard(title: 'Current Week', value: '02'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({required this.title, required this.value, super.key});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(child: Text(title)),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
