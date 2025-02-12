import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalyzer/const/color_palette.dart';
import 'package:vitalyzer/presentation/widget/bmi_gauge.dart';
import 'package:vitalyzer/presentation/widget/user_info_container.dart';
import 'package:vitalyzer/util/funtions.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool _isLoading = true;
  late SharedPreferences prefs;
  double? bodyMassIndexLevel;
  String? bmiAdvice;
  List<String> parsedText = [];

  @override
  void initState() {
    super.initState();
    _loadSharedPrefs();
  }

  Future<void> _loadSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      bodyMassIndexLevel = prefs.getDouble('bodyMassIndexLevel');
      bmiAdvice = prefs.getString('bmiAdvice');
    });
    await _parseText(text: bmiAdvice!);
  }

  Future<void> _parseText({required String text}) async {
    setState(() {
      parsedText = text
          .split('(x)') // Split at each "(x)"
          .map((part) => part.trim()) // Trim whitespace from each part
          .where((part) => part.isNotEmpty) // Remove empty strings
          .toList(); // Convert to a list
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.beige,
      appBar: AppBar(
        backgroundColor: ColorPalette.beige,
        foregroundColor: ColorPalette.green,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ColorPalette.lightGreen),
            )
          : Padding(
              padding: const EdgeInsets.only(bottom: 50, right: 25, left: 25),
              child: SizedBox(
                height: Get.height,
                width: Get.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BMIGauge(bmiValue: bodyMassIndexLevel!),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          gradient: LinearGradient(colors: [
                            Colors.blue,
                            Colors.green,
                            Colors.yellow,
                            Colors.orange,
                            Colors.red,
                          ]),
                        ),
                        child: ElevatedButton(
                          onPressed: () => _openCalculator(),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateColor.transparent,
                            shadowColor: WidgetStateColor.transparent,
                            fixedSize: WidgetStatePropertyAll(
                              Size.fromWidth(Get.width * 0.5),
                            ),
                          ),
                          child: const Text(
                            'Custom Calculation',
                            style: TextStyle(color: ColorPalette.beige),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemCount: parsedText.length,
                          itemBuilder: (context, index) {
                            var scrollController = ScrollController();
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: ColorPalette.lightGreen.withOpacity(0.5),
                                border: Border.all(
                                    color: ColorPalette.lightGreen, width: 3),
                              ),
                              height: Get.height,
                              width: Get.width * 0.75,
                              child: Scrollbar(
                                controller: scrollController,
                                scrollbarOrientation:
                                    ScrollbarOrientation.right,
                                trackVisibility: true,
                                interactive: true,
                                thickness: 6,
                                radius: const Radius.circular(30),
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MarkdownBody(
                                        data: parsedText[index],
                                        styleSheet: MarkdownStyleSheet(
                                          p: const TextStyle(
                                            fontSize: 14,
                                            color: ColorPalette.darkGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _openCalculator() {
    double? selectedWeight;
    int? selectedHeight;
    bool isSelectionComplete = false;
    bool showResult = false;
    double? bmiValue;

    void updateSelectionStatus() {
      setState(() {
        isSelectionComplete =
            (selectedHeight != null) && (selectedWeight != null);
      });
    }

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
              width: Get.width,
              child: showResult
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          const Text(
                            "Result",
                            style: TextStyle(
                              color: ColorPalette.darkGreen,
                              fontSize: 20,
                            ),
                          ),
                          const Divider(
                              color: ColorPalette.lightGreen, thickness: 2),
                          const SizedBox(height: 15),
                          BMIGauge(bmiValue: bmiValue!),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        const Text(
                          "Custom Calculation",
                          style: TextStyle(
                            color: ColorPalette.darkGreen,
                            fontSize: 20,
                          ),
                        ),
                        const Divider(
                            color: ColorPalette.lightGreen, thickness: 2),
                        const SizedBox(height: 15),
                        UserInfoContainer(
                          text: 'Height',
                          icon: Icons.height,
                          buttonText: selectedHeight != null
                              ? selectedHeight.toString()
                              : selectedHeight,
                          unit: 'cm',
                          onTap: () => _showHeightSelector(
                            selectedHeight: selectedHeight,
                            context: context,
                            onHeightSelected: (height) {
                              setState(() {
                                selectedHeight = height;
                              });
                              updateSelectionStatus();
                            },
                          ),
                        ),
                        UserInfoContainer(
                          text: 'Weight',
                          icon: Icons.scale,
                          buttonText: selectedWeight != null
                              ? selectedWeight.toString()
                              : selectedWeight,
                          unit: 'kg',
                          onTap: () => _showWeightSelector(
                            selectedWeight: selectedWeight,
                            context: context,
                            onWeightSelected: (weight) {
                              setState(() {
                                selectedWeight = weight;
                              });
                              updateSelectionStatus();
                            },
                          ),
                        ),
                        const Spacer(flex: 1),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: ElevatedButton(
                            onPressed: isSelectionComplete
                                ? () {
                                    setState(
                                      () {
                                        bmiValue = calculateBodyMassIndex(
                                          kgWeight: selectedWeight!,
                                          cmHeight: selectedHeight!,
                                        );
                                        showResult = true;
                                      },
                                    );
                                  }
                                : null,
                            style: ButtonStyle(
                              fixedSize: WidgetStatePropertyAll(
                                  Size.fromWidth(Get.width * 0.5)),
                              backgroundColor: isSelectionComplete
                                  ? const WidgetStatePropertyAll(
                                      ColorPalette.green)
                                  : WidgetStatePropertyAll(
                                      ColorPalette.green.withOpacity(0.5)),
                            ),
                            child: const Text(
                              'Calculate',
                              style: TextStyle(
                                color: ColorPalette.beige,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  void _showHeightSelector({
    required int? selectedHeight,
    required BuildContext context,
    required void Function(int)
        onHeightSelected, // Callback to update the state
  }) {
    // Define the range for height
    const int minHeight = 120;
    const int maxHeight = 250;

    // Initialize scroll controller with the selected or default height (170 cm)
    FixedExtentScrollController scrollController = FixedExtentScrollController(
      initialItem: (selectedHeight ?? 170) - minHeight,
    );

    // Set initial height only if it hasn't been set before
    int height = selectedHeight ?? 170;

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
                    "Height",
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
                          CupertinoPicker(
                            scrollController: scrollController,
                            itemExtent: 40,
                            selectionOverlay: Container(
                              decoration: BoxDecoration(
                                color: ColorPalette.lightGreen.withOpacity(0.5),
                                border: Border.all(
                                  color: ColorPalette.lightGreen,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                height = (index + minHeight);
                              });
                            },
                            children: List.generate(
                              maxHeight - minHeight + 1,
                              (index) => Center(
                                child: Text(
                                  "${index + minHeight}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          // Fixed "cm" text overlay
                          Positioned(
                            right: Get.width * 0.25,
                            child: const Text(
                              'cm',
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
                  ElevatedButton(
                    style: ButtonStyle(
                      fixedSize: WidgetStatePropertyAll(
                        Size.fromWidth(Get.width * 0.5),
                      ),
                      backgroundColor:
                          const WidgetStatePropertyAll(ColorPalette.green),
                    ),
                    onPressed: () {
                      onHeightSelected(height); // Call the callback
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Select',
                      style: TextStyle(color: ColorPalette.beige),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWeightSelector({
    required double? selectedWeight,
    required BuildContext context,
    required void Function(double)
        onWeightSelected, // Callback to update the state
  }) {
    // Define the range for weight
    const int minIntegerPart = 30;
    const int maxIntegerPart = 200;
    const int minFractionPart = 0;
    const int maxFractionPart = 9;

    // Extract integer and fractional parts of the selected weight
    int initialIntegerPart = selectedWeight?.floor() ?? 70;
    int initialFractionPart = ((selectedWeight ?? 70) * 10 % 10).toInt();

    // Scroll controllers for the two pickers
    FixedExtentScrollController integerPartController =
        FixedExtentScrollController(
      initialItem: initialIntegerPart - minIntegerPart,
    );
    FixedExtentScrollController fractionPartController =
        FixedExtentScrollController(
      initialItem: initialFractionPart,
    );

    // Set initial weight only if it hasn't been set before
    double weight =
        selectedWeight ?? initialIntegerPart + (initialFractionPart / 10.0);

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
                    "Weight",
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
                                      weight = initialIntegerPart +
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
                                      initialFractionPart = index;
                                      weight = initialIntegerPart +
                                          initialFractionPart / 10.0;
                                    });
                                  },
                                  children: List.generate(
                                    maxFractionPart - minFractionPart + 1,
                                    (index) => Center(
                                      child: Text(
                                        "$index",
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
                            right: Get.width * 0.1,
                            child: const Text(
                              'kg',
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
                  ElevatedButton(
                    style: ButtonStyle(
                      fixedSize: WidgetStatePropertyAll(
                        Size.fromWidth(Get.width * 0.5),
                      ),
                      backgroundColor:
                          const WidgetStatePropertyAll(ColorPalette.green),
                    ),
                    onPressed: () {
                      onWeightSelected(weight); // Call the callback
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Select',
                      style: TextStyle(color: ColorPalette.beige),
                    ),
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
