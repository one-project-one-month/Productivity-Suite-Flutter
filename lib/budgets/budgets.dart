import 'package:flutter/material.dart';
import 'package:productivity_suite_flutter/budgets/custom_button.dart';
import 'package:productivity_suite_flutter/budgets/transcation_model.dart';
import 'package:intl/intl.dart';

class BudgetPage extends StatelessWidget {
  BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              BudgetCardWidget(
                color: Colors.blue,
                title: 'Total Balance',
                value: 5000,
              ),
              BudgetCardWidget(
                color: Colors.green,
                title: 'Income',
                value: 2000,
              ),
              BudgetCardWidget(
                color: Colors.red,
                title: 'Expenses',
                value: 3000,
              ),
              ContainerWidget(widget: AddTranscationWidget()),
              ContainerWidget(widget: RecentTranscationWidget()),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTranscationWidget extends StatelessWidget {
  AddTranscationWidget({super.key});
  List<String> type = ["Income", "Expense"];
  List<String> usage = [
    'Food',
    "Housing",
    "Transportation",
    "Entertainment",
    "Utilities",
    "Healthcare",
    "Salary",
    "Investement",
    "Other",
  ];
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "\$ Add Transaction",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          TextFieldWidget(
            txtController: TextEditingController(),
            hintText: "Description",
            maxLine: 5,
          ),
          TextFieldWidget(
            txtController: TextEditingController(),
            hintText: "Amount",
          ),
          DropdownButtonFormField(
            decoration: InputDecoration(
              hintText: "Income",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            items:
                type
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: (value) {},
          ),
          DropdownButtonFormField(
            decoration: InputDecoration(
              hintText: "Food",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            items:
                usage
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: (value) {},
          ),
          CustomButtonWidget(onTapFunc: () {}, text: "Add"),
        ],
      ),
    );
  }
}

class RecentTranscationWidget extends StatelessWidget {
  RecentTranscationWidget({super.key});
  List<TranscationModel> temps = [
    TranscationModel(
      id: "422",
      type: "Income",
      usage: "Food",
      description: "Snacks",
      createDate: DateTime.now(),
      amount: 30000,
    ),
    TranscationModel(
      id: "343",
      type: "Expense",
      usage: "Healthcare",
      description: "Medicine",
      createDate: DateTime.now(),
      amount: 200000000,
    ),
    TranscationModel(
      id: "424",
      type: "Income",
      usage: "Investment",
      description: "Monthly",
      createDate: DateTime.now(),
      amount: 3000000,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "Recent Transcation",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              TextButton(onPressed: () {}, child: Text("See More")),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: temps.length,
            itemBuilder: (context, index) {
              TranscationModel obj = temps[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color.fromARGB(255, 216, 216, 216),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  spacing: 8,
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 2,
                      child:
                          obj.type == "Income"
                              ? Icon(Icons.arrow_downward)
                              : Icon(Icons.arrow_upward),
                    ),
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
                            "${obj.usage} . ${DateFormat('MMMM d, y').format(obj.createDate)}",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 131, 131, 131),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      flex: 4,
                      child: FittedBox(
                        child: Text(
                          obj.type == "Income"
                              ? "+ \$${obj.amount}"
                              : "- \$${obj.amount}",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color:
                                obj.type == "Income"
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.delete),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({
    super.key,
    required this.txtController,
    required this.hintText,
    this.maxLine = 1,
  });
  final TextEditingController txtController;
  final String hintText;
  final int maxLine;

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLine,
      controller: txtController,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
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

class BudgetCardWidget extends StatelessWidget {
  const BudgetCardWidget({
    super.key,
    required this.color,
    required this.title,
    required this.value,
  });
  final Color color;
  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(6),
      padding: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),

      height: 80,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color.fromARGB(255, 223, 223, 223),
              fontSize: 18,
            ),
          ),
          Text(
            "\$ ${value.toString()}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
