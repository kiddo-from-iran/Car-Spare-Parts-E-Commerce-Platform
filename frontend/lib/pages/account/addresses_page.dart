import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import 'account_addresses_section.dart';
import 'account_page_scaffold.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountPageScaffold(
      title: AppStrings.myAddresses,
      scrollable: true,
      child: const AccountAddressesSection(),
    );
  }
}
