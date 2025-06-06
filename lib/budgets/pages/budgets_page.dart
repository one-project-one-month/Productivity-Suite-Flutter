import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:productivity_suite_flutter/budgets/models/category_model.dart';
import 'package:productivity_suite_flutter/budgets/pages/category_page.dart';
import 'package:productivity_suite_flutter/budgets/pages/transcation_history_page.dart';
import 'package:productivity_suite_flutter/budgets/providers/category_provider.dart';
import 'package:productivity_suite_flutter/budgets/providers/transcation_provider.dart';
import 'package:productivity_suite_flutter/budgets/widgets/custom_button.dart';
import 'package:productivity_suite_flutter/budgets/models/transcation_model.dart';
import 'package:intl/intl.dart';
import 'package:productivity_suite_flutter/budgets/widgets/textfield_widget.dart';
import 'package:provider/provider.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample expense data
    final expenseData = {'Entertainment': 100000.0};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Budget Tracker',
          style: TextStyle(
            color: Colors.deepPurpleAccent,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ContainerWithBorder(
                color: Colors.blue,
                title: 'Total Balance',
                child: Text(
                  "-MMK 100,000",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ContainerWithBorder(
                color: Colors.green,
                title: 'Monthly Budget',
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Budget: MMK 2,000,000",
                            style: TextStyle(fontSize: 16),
                          ),
                          Spacer(),
                          TextButton(onPressed: () {}, child: Text("Edit")),
                        ],
                      ),
                      LinearProgressIndicator(
                        minHeight: 8,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        value: 0.05,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.deepPurpleAccent,
                      ),
                      Row(
                        children: [
                          Text(
                            "MMK 1,900,000 remaining",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Spacer(),
                          Text(
                            "5% used",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // ContainerWithBorder(
              //   color: Colors.red,
              //   title: 'Recent Activity',
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 10),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //       children: [
              //         Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               "Income",
              //               style: TextStyle(
              //                 color: Colors.grey.shade700,
              //                 fontSize: 18,
              //               ),
              //             ),
              //             Text(
              //               "MMK 0",
              //               style: TextStyle(
              //                 color: Colors.green,
              //                 fontSize: 18,
              //                 fontWeight: FontWeight.w700,
              //               ),
              //             ),
              //           ],
              //         ),
              //         Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               "Expenses",
              //               style: TextStyle(
              //                 color: Colors.grey.shade700,
              //                 fontSize: 18,
              //               ),
              //             ),
              //             Text(
              //               "MMK 100,000",
              //               style: TextStyle(
              //                 color: Colors.red,
              //                 fontSize: 18,
              //                 fontWeight: FontWeight.w700,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Transactions",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepPurpleAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(Icons.add),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder:
                              (context) => Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: AddTranscationWidget(),
                              ),
                        );
                      },
                      label: Text("Add Transcation"),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepPurpleAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(Icons.add),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CategoryPage(),
                          ),
                        );
                      },
                      label: Text("Category"),
                    ),
                  ],
                ),
              ),
              ContainerWidget(
                widget: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RecentTranscationWidget(),
                ),
              ),
              ContainerWidget(
                widget: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpenseBreakdownWidget(expenses: expenseData),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTranscationWidget extends StatelessWidget {
  AddTranscationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final providerTranscation = context.read<TranscationProvider>();
    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Add New Transaction",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          TextFieldWidget(
            txtController: providerTranscation.txtDescription,
            hintText: "Description",
            maxLine: 5,
          ),
          TextFieldWidget(
            txtController: providerTranscation.txtAmount,
            hintText: "Amount",
            keyboardType: TextInputType.number,
          ),
          // DropdownButtonFormField(
          //   decoration: InputDecoration(
          //     hintText: "Income",
          //     border: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(10),
          //       borderSide: BorderSide(color: Colors.grey),
          //     ),
          //   ),
          //   items:
          //       type
          //           .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          //           .toList(),
          //   onChanged: (value) {},
          // ),
          Consumer<CategoryProvider>(
            builder:
                (context, provider, child) => DropdownButtonFormField(
                  decoration: InputDecoration(
                    hintText: "Food",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                  value: providerTranscation.category,
                  items:
                      provider.categories
                          .map(
                            (e) =>
                                DropdownMenuItem(value: e, child: Text(e.name)),
                          )
                          .toList(),
                  onChanged: (value) {
                    providerTranscation.changeCategory(value);
                  },
                ),
          ),
          CustomButtonWidget(
            onTapFunc: () async {
              final success = await providerTranscation.postNewTranscation();
              if (success) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Something went wrong!"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            text: "Add",
          ),
        ],
      ),
    );
  }
}

class ExpenseBreakdownWidget extends StatelessWidget {
  final Map<String, double> expenses;

  const ExpenseBreakdownWidget({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Expense Breakdown",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 0,
                sections: _createSections(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ..._createLegendItems(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _createSections() {
    if (expenses.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 100,
          title: '',
          radius: 100,
        ),
      ];
    }

    final total = expenses.values.reduce((a, b) => a + b);
    final colors = {
      'Entertainment': Colors.amber,
      'Food': Colors.blue,
      'Healthcare': Colors.red,
      'Transportation': Colors.green,
      'Housing': Colors.purple,
      'Utilities': Colors.orange,
      'Others': Colors.grey,
    };

    return expenses.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: colors[entry.key] ?? Colors.grey,
        value: entry.value,
        title: '',
        radius: 100,
      );
    }).toList();
  }

  List<Widget> _createLegendItems() {
    if (expenses.isEmpty) {
      return [
        Row(
          children: [
            Container(width: 16, height: 16, color: Colors.grey[300]),
            const SizedBox(width: 8),
            Text('No expenses', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ];
    }

    final total = expenses.values.reduce((a, b) => a + b);
    final colors = {
      'Entertainment': Colors.amber,
      'Food': Colors.blue,
      'Healthcare': Colors.red,
      'Transportation': Colors.green,
      'Housing': Colors.purple,
      'Utilities': Colors.orange,
      'Others': Colors.grey,
    };

    return expenses.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[entry.key] ?? Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.key} (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class RecentTranscationWidget extends StatelessWidget {
  RecentTranscationWidget({super.key});
  // List<TranscationModel> temps = [
  //   TranscationModel(
  //     id: "422",
  //     type: "Income",
  //     usage: "Food",
  //     description: "Snacks",
  //     createDate: DateTime.now(),
  //     amount: 30000,
  //   ),
  //   TranscationModel(
  //     id: "343",
  //     type: "Expense",
  //     usage: "Healthcare",
  //     description: "Medicine",
  //     createDate: DateTime.now(),
  //     amount: 200000000,
  //   ),
  //   TranscationModel(
  //     id: "424",
  //     type: "Income",
  //     usage: "Investment",
  //     description: "Monthly",
  //     createDate: DateTime.now(),
  //     amount: 3000000,
  //   ),
  // ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              "Transaction History",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TranscationHistoryPage(),
                  ),
                );
              },
              child: Text("See More"),
            ),
          ],
        ),
        Consumer<TranscationProvider>(
          builder:
              (context, provider, child) => ListView.separated(
                separatorBuilder: (context, index) => Divider(),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: provider.transcationsList.length,
                itemBuilder: (context, index) {
                  TranscationModel obj = provider.transcationsList[index];
                  return Container(
                    // decoration: BoxDecoration(
                    //   borderRadius: BorderRadius.all(Radius.circular(10)),
                    //   border: Border.all(color: Colors.grey.shade300),
                    // ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      spacing: 8,
                      children: [
                        // Flexible(
                        //   flex: 2,
                        //   child:
                        //       obj.type == "Income"
                        //           ? Icon(Icons.arrow_downward)
                        //           : Icon(Icons.arrow_upward),
                        // ),
                        Expanded(
                          flex: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                obj.description,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                "${obj.categoryName} . \n${DateFormat('MMMM d, y').format(DateTime.fromMillisecondsSinceEpoch(obj.transactionDate * 1000))}",
                                style: TextStyle(
                                  color: const Color.fromARGB(
                                    255,
                                    131,
                                    131,
                                    131,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          flex: 6,
                          child: FittedBox(
                            child: Text(
                              "- \$${obj.amount}",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 2,
                          child: IconButton(
                            onPressed: () async {
                              final success = await provider.removeTransaction(
                                obj.id,
                              );
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Transaction deleted!"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Transaction not deleted!"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.delete),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}

class ContainerWidget extends StatelessWidget {
  const ContainerWidget({super.key, required this.widget});
  final Widget widget;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(6),
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 216, 216, 216),
          width: 2,
        ),
        color: const Color.fromARGB(255, 251, 251, 251),
        borderRadius: BorderRadius.circular(10),
      ),
      child: widget,
    );
  }
}

class ContainerWithBorder extends StatelessWidget {
  const ContainerWithBorder({
    super.key,
    required this.color,
    required this.title,
    required this.child,
  });
  final Color color;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(6),
      padding: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
      ),

      // height: 150,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Padding(padding: const EdgeInsets.all(8.0), child: child),
        ],
      ),
    );
  }
}
