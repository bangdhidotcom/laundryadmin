import 'package:get/get.dart';
import 'package:laundry3b1titik0/services/admin_notification_service.dart';

class MainPageController extends GetxController {
  var selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    AdminNotificationService().updateAdminToken();
  }

  void changePage(int index) {
    selectedIndex.value = index;
  }
}
