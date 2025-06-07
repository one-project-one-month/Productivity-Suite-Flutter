import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:productivity_suite_flutter/budgets/models/transcation_model.dart';
import 'package:productivity_suite_flutter/budgets/providers/transcation_provider.dart';
import 'package:provider/provider.dart';

class TranscationHistoryPage extends StatelessWidget {
  const TranscationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Transcation History",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Consumer<TranscationProvider>(
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
      ),
    );
  }
}
