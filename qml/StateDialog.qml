import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import QtQuick.Controls.Styles 1.3
import org.ethereum.qml.QEther 1.0
import "js/QEtherHelper.js" as QEtherHelper
import "js/TransactionHelper.js" as TransactionHelper
import "."

Window {
	id: modalStateDialog
	modality: Qt.ApplicationModal

	width: 570
	height: 480
	title: qsTr("Edit State")
	visible: false
	color: StateDialogStyle.generic.backgroundColor

	property alias stateTitle: titleField.text
	property alias isDefault: defaultCheckBox.checked
	property int stateIndex
	property var stateTransactions: []
	property var stateAccounts: []
	signal accepted

	function open(index, item, setDefault) {
		stateIndex = index;
		stateTitle = item.title;
		transactionsModel.clear();

		stateTransactions = [];
		var transactions = item.transactions;
		for (var t = 0; t < transactions.length; t++) {
			transactionsModel.append(item.transactions[t]);
			stateTransactions.push(item.transactions[t]);
		}

		accountsModel.clear();
		stateAccounts = [];
		for (var k = 0; k < item.accounts.length; k++)
		{
			accountsModel.append(item.accounts[k]);
			stateAccounts.push(item.accounts[k]);
		}

		modalStateDialog.setX((Screen.width - width) / 2);
		modalStateDialog.setY((Screen.height - height) / 2);

		visible = true;
		isDefault = setDefault;
		titleField.focus = true;
		defaultCheckBox.enabled = !isDefault;
		forceActiveFocus();
	}

	function close() {
		visible = false;
	}

	function getItem() {
		var item = {
			title: stateDialog.stateTitle,
			transactions: [],
			accounts: []
		}
		item.transactions = stateTransactions;
		item.accounts = stateAccounts;
		return item;
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 10
		ColumnLayout {
			id: dialogContent
			anchors.top: parent.top

			RowLayout
			{
				Layout.fillWidth: true
				DefaultLabel {
					Layout.preferredWidth: 75
					text: qsTr("Title")
				}
				DefaultTextField
				{
					id: titleField
					Layout.fillWidth: true
				}
			}

			CommonSeparator
			{
				Layout.fillWidth: true
			}

			RowLayout
			{
				Layout.fillWidth: true

				Rectangle
				{
					Layout.preferredWidth: 75
					DefaultLabel {
						id: accountsLabel
						Layout.preferredWidth: 75
						text: qsTr("Accounts")
					}

					Button
					{
						anchors.top: accountsLabel.bottom
						anchors.topMargin: 10
						iconSource: "qrc:/qml/img/plus.png"
						action: newAccountAction
					}

					Action {
						id: newAccountAction
						tooltip: qsTr("Add new Account")
						onTriggered:
						{
							var account = stateListModel.newAccount("1000000", QEther.Ether);
							stateAccounts.push(account);
							accountsModel.append(account);
						}
					}
				}

				TableView
				{
					id: accountsView
					Layout.fillWidth: true
					model: accountsModel
					TableViewColumn {
						role: "name"
						title: qsTr("Name")
						width: 120
						delegate: Item {
							Rectangle
							{
								height: 25
								width: parent.width
								DefaultTextField {
									anchors.verticalCenter: parent.verticalCenter
									onTextChanged: {
										if (styleData.row > -1)
											stateAccounts[styleData.row].name = text;
									}
									text:  {
										return styleData.value
									}
								}
							}
						}
					}

					TableViewColumn {
						role: "balance"
						title: qsTr("Balance")
						width: 200
						delegate: Item {
							Ether {
								id: balanceField
								edit: true
								displayFormattedValue: false
								value: styleData.value
							}
						}
					}
					rowDelegate:
						Rectangle {
						color: styleData.alternate ? "transparent" : "#f0f0f0"
						height: 30;
					}
				}
			}

			CommonSeparator
			{
				Layout.fillWidth: true
			}

			RowLayout
			{
				Layout.fillWidth: true
				DefaultLabel {
					Layout.preferredWidth: 75
					text: qsTr("Default")
				}
				CheckBox {
					id: defaultCheckBox
					Layout.fillWidth: true
				}
			}

			CommonSeparator
			{
				Layout.fillWidth: true
			}
		}

		ColumnLayout {
			anchors.top: dialogContent.bottom
			anchors.topMargin: 5
			spacing: 0
			RowLayout
			{
				Layout.preferredWidth: 150
				DefaultLabel {
					text: qsTr("Transactions: ")
				}

				Button
				{
					iconSource: "qrc:/qml/img/plus.png"
					action: newTrAction
					width: 10
					height: 10
					anchors.right: parent.right
				}

				Action {
					id: newTrAction
					tooltip: qsTr("Create a new transaction")
					onTriggered: transactionsModel.addTransaction()
				}
			}

			ScrollView
			{
				Layout.fillHeight: true
				Layout.preferredWidth: 300
				Column
				{
					Layout.fillHeight: true
					Repeater
					{
						id: trRepeater
						model: transactionsModel
						delegate: transactionRenderDelegate
						visible: transactionsModel.count > 0
						height: 20 * transactionsModel.count
					}
				}
			}

			CommonSeparator
			{
				Layout.fillWidth: true
			}
		}

		RowLayout
		{
			anchors.bottom: parent.bottom
			anchors.right: parent.right;

			Button {
				text: qsTr("OK");
				onClicked: {
					close();
					accepted();
				}
			}
			Button {
				text: qsTr("Cancel");
				onClicked: close();
			}
		}
	}

	ListModel {
		id: accountsModel

		function removeAccount(_i)
		{
			accountsModel.remove(_i);
			stateAccounts.splice(_i, 1);
		}
	}

	ListModel {
		id: transactionsModel

		function editTransaction(index) {
			transactionDialog.stateAccounts = stateAccounts;
			transactionDialog.open(index, transactionsModel.get(index));
		}

		function addTransaction() {

			// Set next id here to work around Qt bug
			// https://bugreports.qt-project.org/browse/QTBUG-41327
			// Second call to signal handler would just edit the item that was just created, no harm done
			var item = TransactionHelper.defaultTransaction();
			transactionDialog.stateAccounts = stateAccounts;
			transactionDialog.open(transactionsModel.count, item);
		}

		function deleteTransaction(index) {
			stateTransactions.splice(index, 1);
			transactionsModel.remove(index);
		}
	}

	Component {
		id: transactionRenderDelegate
		RowLayout {
			DefaultLabel {
				Layout.preferredWidth: 150
				text: functionId
			}

			Button
			{
				id: deleteBtn
				iconSource: "qrc:/qml/img/delete_sign.png"
				action: deleteAction
				width: 10
				height: 10
				Action {
					id: deleteAction
					tooltip: qsTr("Delete")
					onTriggered: transactionsModel.deleteTransaction(index)
				}
			}

			Button
			{
				iconSource: "qrc:/qml/img/edit.png"
				action: editAction
				visible: !stdContract
				width: 10
				height: 10
				Action {
					id: editAction
					tooltip: qsTr("Edit")
					onTriggered: transactionsModel.editTransaction(index)
				}
			}
		}
	}

	TransactionDialog
	{
		id: transactionDialog
		onAccepted:
		{
			var item = transactionDialog.getItem();

			if (transactionDialog.transactionIndex < transactionsModel.count) {
				transactionsModel.set(transactionDialog.transactionIndex, item);
				stateTransactions[transactionDialog.transactionIndex] = item;
			} else {
				transactionsModel.append(item);
				stateTransactions.push(item);
			}
		}
	}
}
