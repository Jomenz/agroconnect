import '../models/order.dart';

class OrderStore {
  OrderStore._();

  static final List<Order> orders = [];

  static void addOrder(Order order) {
    orders.add(order);
  }
}