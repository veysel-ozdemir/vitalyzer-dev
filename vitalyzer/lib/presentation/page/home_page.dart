import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalyzer/const/color_palette.dart';
import 'package:vitalyzer/presentation/widget/grid_item.dart';
import 'package:vitalyzer/util/extension.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int waterBottleItemCount = 0;
  final double waterBottleCapacity = 0.5;

  double? dailyWaterLimit;
  int? gainedCalories;
  int? dailyCalorieLimit;
  int drankWaterBottle = 0;
  List<bool> waterBottleItemStates = []; // Pressed states of items
  late SharedPreferences prefs;

  String greeting = '';
  late Timer timer;

  @override
  void initState() {
    super.initState();
    _loadSharedPrefs(); // Load persisted value when page initializes
    _updateGreeting();
    timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateGreeting();
    });
  }

  Future<void> _loadSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      dailyWaterLimit = prefs.getDouble('dailyWaterLimit');
      waterBottleItemCount = (dailyWaterLimit! / waterBottleCapacity).toInt();
      gainedCalories = prefs.getInt('gainedCalories');
      dailyCalorieLimit = prefs.getInt('dailyCalorieLimit');
      drankWaterBottle = prefs.getInt('drankWaterBottle')!;

      final savedStates = prefs.getStringList('waterBottleItemStates');
      waterBottleItemStates = savedStates != null
          ? savedStates.map((e) => e == 'true').toList()
          : List.generate(waterBottleItemCount, (_) => false);
    });
  }

  Future<void> _saveWaterData() async {
    await prefs.setInt('drankWaterBottle', drankWaterBottle);
    await prefs.setStringList('waterBottleItemStates',
        waterBottleItemStates.map((e) => e.toString()).toList());
  }

  void _updateWaterBottleCount(int index, bool isPressed) {
    setState(() {
      if (isPressed) {
        drankWaterBottle++;
      } else {
        drankWaterBottle--;
      }
      waterBottleItemStates[index] = isPressed; // Update state for this item
      _saveWaterData(); // Save updated value
    });
  }

  Future<void> _updateWaterLimitData() async {
    await prefs.setDouble('dailyWaterLimit', dailyWaterLimit!);
    await prefs.setInt('drankWaterBottle', drankWaterBottle);
    await prefs.setStringList('waterBottleItemStates',
        waterBottleItemStates.map((e) => e.toString()).toList());
  }

  void _updateGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    String newGreeting;

    if (hour >= 5 && hour < 12) {
      newGreeting = 'Good Morning,';
    } else if (hour == 12) {
      newGreeting = 'Good Noon,';
    } else if (hour > 12 && hour < 17) {
      newGreeting = 'Good Afternoon,';
    } else if (hour >= 17 && hour < 21) {
      newGreeting = 'Good Evening,';
    } else {
      newGreeting = 'Good Night,';
    }

    if (newGreeting != greeting) {
      setState(() {
        greeting = newGreeting;
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = context.deviceSize;

    return Scaffold(
      backgroundColor: ColorPalette.beige,
      body: waterBottleItemStates.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show a loader
          : Padding(
              padding: const EdgeInsets.only(
                  top: 50, bottom: 25, right: 25, left: 25),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              color: ColorPalette.darkGreen.withOpacity(0.75),
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'Leonardo!',
                            style: TextStyle(
                              color: ColorPalette.darkGreen.withOpacity(0.75),
                              fontSize: 36,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {},
                        child: Container(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorPalette.darkGreen,
                                width: 3,
                              ),
                            ),
                            child: FlutterLogo(
                              size: deviceSize.height * 0.05,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 25, bottom: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(10),
                                height: deviceSize.height * 0.25,
                                width: deviceSize.height * 0.25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ColorPalette.green,
                                    width: 3,
                                  ),
                                ),
                                child: const Text('Pie Chart'),
                              ),
                            ),
                            Text(
                              '$gainedCalories / $dailyCalorieLimit\nkcal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ColorPalette.darkGreen.withOpacity(0.75),
                                fontSize: 14,
                              ),
                            )
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            '...',
                            style: TextStyle(
                              color: ColorPalette.darkGreen.withOpacity(0.75),
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Water Counter',
                            style: TextStyle(
                              color: ColorPalette.darkGreen.withOpacity(0.75),
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            "${drankWaterBottle * waterBottleCapacity} / $dailyWaterLimit L",
                            style: TextStyle(
                              color: ColorPalette.darkGreen.withOpacity(0.75),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          TextButton(
                            onPressed: () => _openWaterCounterSettings(
                              context: context,
                              onWaterLimitUpdate: (waterLimit) async {
                                setState(() {
                                  drankWaterBottle = 0;
                                  dailyWaterLimit = waterLimit;
                                  waterBottleItemCount =
                                      (dailyWaterLimit! / waterBottleCapacity)
                                          .toInt();
                                  waterBottleItemStates = List.generate(
                                    waterBottleItemCount,
                                    (_) => false,
                                  );
                                });

                                await _updateWaterLimitData();
                              },
                            ),
                            child: Text(
                              '...',
                              style: TextStyle(
                                color: ColorPalette.darkGreen.withOpacity(0.75),
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20)
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      height: deviceSize.height * 0.15,
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6, // Number of items per row
                          crossAxisSpacing:
                              2, // Space between items horizontally
                          mainAxisSpacing: 5, // Space between rows
                        ),
                        itemCount: waterBottleItemCount,
                        itemBuilder: (context, index) => GridItem(
                          index: index,
                          isPressed: waterBottleItemStates[index],
                          onToggle: (isPressed) =>
                              _updateWaterBottleCount(index, isPressed),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 25, bottom: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Spacer(flex: 1),
                        InkWell(
                          onTap: () {},
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(5),
                            height: deviceSize.height * 0.075,
                            width: deviceSize.height * 0.075,
                            child: Image.asset(
                                'assets/illustrations/checklist.png'),
                          ),
                        ),
                        const Spacer(flex: 3),
                        InkWell(
                          onTap: () {},
                          child: Container(
                            alignment: Alignment.center,
                            height: deviceSize.height * 0.075,
                            width: deviceSize.height * 0.075,
                            child:
                                Image.asset('assets/illustrations/camera.png'),
                          ),
                        ),
                        const Spacer(flex: 3),
                        InkWell(
                          onTap: () {},
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(5),
                            height: deviceSize.height * 0.075,
                            width: deviceSize.height * 0.075,
                            child: Image.asset(
                                'assets/illustrations/analytics.png'),
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  void _openWaterCounterSettings({
    required BuildContext context,
    required void Function(double) onWaterLimitUpdate,
  }) {
    const int minIntegerPart = 0;
    const int maxIntegerPart = 4;
    const int fractionPartRange = 5;

    int initialIntegerPart = dailyWaterLimit!.floor();
    int initialFractionPart = (dailyWaterLimit! * 10 % 10).toInt();

    // Scroll controllers for the two pickers
    FixedExtentScrollController integerPartController =
        FixedExtentScrollController(
      initialItem: initialIntegerPart - minIntegerPart,
    );
    FixedExtentScrollController fractionPartController =
        FixedExtentScrollController(
      initialItem: initialFractionPart,
    );

    final deviceSize = context.deviceSize;

    double waterLimit = dailyWaterLimit!;

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorPalette.beige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        side: BorderSide(
          color: ColorPalette.lightGreen,
          width: 3,
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Daily Water Limit",
                    style: TextStyle(
                      color: ColorPalette.darkGreen,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          pickerTextStyle:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: ColorPalette.darkGreen,
                                  ),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(flex: 1),
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: integerPartController,
                                  itemExtent: 40,
                                  selectionOverlay: Container(
                                    decoration: BoxDecoration(
                                      color: ColorPalette.lightGreen
                                          .withOpacity(0.5),
                                      border: const Border(
                                        left: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                        top: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                        bottom: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                  onSelectedItemChanged: (int index) {
                                    setState(() {
                                      initialIntegerPart =
                                          index + minIntegerPart;
                                      waterLimit = initialIntegerPart +
                                          initialFractionPart / 10.0;
                                    });
                                  },
                                  children: List.generate(
                                    maxIntegerPart - minIntegerPart + 1,
                                    (index) => Center(
                                      child: Text(
                                        "${index + minIntegerPart}",
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: fractionPartController,
                                  itemExtent: 40,
                                  selectionOverlay: Container(
                                    decoration: BoxDecoration(
                                      color: ColorPalette.lightGreen
                                          .withOpacity(0.5),
                                      border: const Border(
                                        right: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                        top: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                        bottom: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                  onSelectedItemChanged: (int index) {
                                    setState(() {
                                      initialFractionPart =
                                          index * fractionPartRange;
                                      waterLimit = initialIntegerPart +
                                          initialFractionPart / 10.0;
                                    });
                                  },
                                  children: List.generate(
                                    2,
                                    (index) => Center(
                                      child: Text(
                                        "${index * fractionPartRange}",
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(flex: 1),
                            ],
                          ),
                          const Center(
                            child: Text(
                              '.',
                              style: TextStyle(
                                color: ColorPalette.darkGreen,
                              ),
                            ),
                          ),
                          Positioned(
                            right: deviceSize.width * 0.1,
                            child: const Text(
                              'L',
                              style: TextStyle(
                                color: ColorPalette.darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  waterLimit != 0.0
                      ? ElevatedButton(
                          style: ButtonStyle(
                            fixedSize: WidgetStatePropertyAll(
                              Size.fromWidth(deviceSize.width * 0.5),
                            ),
                            backgroundColor: const WidgetStatePropertyAll(
                                ColorPalette.green),
                          ),
                          onPressed: () {
                            onWaterLimitUpdate(waterLimit); // Call the callback
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Select',
                            style: TextStyle(color: ColorPalette.beige),
                          ),
                        )
                      : const Text(
                          "The limit can't be zero.",
                          style: TextStyle(
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
