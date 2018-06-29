from appJar import gui
import sys
import glob
import serial
import re
from PIL import Image, ImageTk
import tkinter as tk
import time
import threading

##########################################################################
# Configuration constants
testChar = b't'
testCharAns = b'y'
downloadChar = b'w'
uploadChar = b'r'
clearChar = b'c'
flits = 3
flitsize = 32

##########################################################################
# Variables
download_image = b'0'
upload_image = b'0'

download_progress = 0
upload_progress = 0

buttonpressed = 0


fig_d_app = None
fig_u_app = None
help_app = None

current_port = ""

serial_available = False  # If false, the list of serials is empty
serial_free = True
#########################################


def serial_ports():
    global serial_available
    global serial_free
    serial_free = False
    # global serial_available
    """ Lists serial port names

        :raises EnvironmentError:
            On unsupported or unknown platforms
        :returns:
            A list of the serial ports available on the system
    """
    if sys.platform.startswith('win'):
        ports = ['COM%s' % (i + 1) for i in range(256)]
    elif sys.platform.startswith('linux') or sys.platform.startswith('cygwin'):
        # this excludes your current terminal "/dev/tty"
        ports = glob.glob('/dev/tty[A-Za-z]*')
    elif sys.platform.startswith('darwin'):
        ports = glob.glob('/dev/tty.*')
    else:
        app.errorBox("Error!", "Unsupported or unknown platform.")
        result = ["-No serial ports available-"]
        serial_available = False
        serial_free = True
        return result

    result = []
    for port in ports:
        try:
            s = serial.Serial(port)
            s.close()
            result.append(port)
        except (OSError, serial.SerialException):
            pass
    if len(result) == 0:
        result = ["-No serial ports available-"]
        serial_available = False
    else:
        serial_available = True
    serial_free = True
    return result


def refreshSerialListTh():
    global serial_free
    serial_free = False
    app.changeOptionBox("list_serial_s", ["-Refreshing list...-"])
    serial_ids = serial_ports()
    app.changeOptionBox("list_serial_s", serial_ids)
    app.setEntry(
        "entry_s1", "Test if the FPGA board is connected to this serial port.", callFunction=False)
    serial_free = True
    return


def refreshSerialList(button):
    serTh = threading.Thread(target=refreshSerialListTh)
    serTh.daemon = True
    serTh.start()
    return


def testSerialButton(button):
    testTh = threading.Thread(target=testSerialTh)
    testTh.daemon = True
    testTh.start()
    return


def testSerialTh():
    global serial_free
    serial_free = False
    try:
        if not serial_available:
            app.setEntry(
                "entry_s1", "Impossible to test. No serial ports available.", callFunction=False)
        else:
            app.setEntry("entry_s1", "Testing...", callFunction=False)
            testSerial_cnt = 10
            while(not(testSerial())):
                testSerial_cnt = testSerial_cnt - 1
                if testSerial_cnt == 0:
                    break
                time.sleep(0.1)
            if testSerial():
                app.setEntry(
                    "entry_s1", "The FPGA board is connected to this serial port.", callFunction=False)
            else:
                app.setEntry(
                    "entry_s1", "The FPGA board is NOT connected to this serial port.", callFunction=False)
    except:
        app.errorBox(
            "Error!", "Impossible to communicate on the selected serial port.")
        app.setEntry(
            "entry_s1", "Test if the FPGA board is connected to this serial port.", callFunction=False)
    serial_free = True
    return


def testSerial():
    ser = serial.Serial(port=app.getOptionBox("list_serial_s"), baudrate=115200,
                        bytesize=8, parity='N', stopbits=1, timeout=0.5, xonxoff=0, rtscts=0)
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    ser.write(testChar)
    s = ser.read(1)
    # print(s)
    ser.reset_input_buffer()  # flush input buffer, discarding all its contents
    # flush output buffer, aborting current output and discard all that is in
    # buffer
    ser.reset_output_buffer()
    ser.close()             # close port
    if s == testCharAns:
        return True
    else:
        return False


def updateTestLabel():
    global current_port
    if current_port != app.getOptionBox("list_serial_s"):
        app.setEntry(
            "entry_s1", "Test if the FPGA board is connected to this serial port.", callFunction=False)
        current_port = app.getOptionBox("list_serial_s")
    return


def writeSerialTh():
    global write_progress
    write_progress = 0
    global serial_free
    serial_free = False

    try:
        # print("writing")
        if not(serial_available):
            app.errorBox("Error!", "No serial ports available.")
        else:
            testSerial_cnt = 10
            while (not(testSerial())):
                # print("testing")
                testSerial_cnt = testSerial_cnt - 1
                if testSerial_cnt == 0:
                    break
                time.sleep(0.1)
            if testSerial():
                # print("sending")
                ser = serial.Serial(port=app.getOptionBox("list_serial_s"), baudrate=115200,
                                    bytesize=8, parity='N', stopbits=1, timeout=None, xonxoff=0, rtscts=0)
                ser.reset_input_buffer()
                ser.reset_output_buffer()
                ser.write(downloadChar)
                for i in range(0, 3):
                    #print("printing: {} to {}".format(32 * i, 31 + 32 * i))
                    ser.write(writeFlits[32 * i:31 + 32 * i])
                    time.sleep(0.1)
                #print("done sending")
                # time.sleep(1)
                upTh = threading.Thread(target=uploadSerialTh)
                upTh.daemon = True
                upTh.start()
            else:
                app.errorBox(
                    "Error!", "down2 - Impossible to communicate with the FPGA board on the selected serial port.")

    except:
        app.errorBox(
            "Error!", "down - Impossible to communicate on the selected serial port.")
        serial_free = True
    return


def uploadSerialTh():
    global upload_data
    global serial_free
    global read_data
    serial_free = False
    try:
        if not serial_available:
            app.errorBox("Error!", "No serial ports available.")
        else:
            testSerial_cnt = 10
            while(not(testSerial())):
                # print("testing")
                testSerial_cnt = testSerial_cnt - 1
                if testSerial_cnt == 0:
                    break
                time.sleep(0.1)
            if testSerial():
                ser = serial.Serial(port=app.getOptionBox(
                    "list_serial_s"), baudrate=115200, bytesize=8, parity='N', stopbits=1, timeout=1, xonxoff=0, rtscts=0)
                ser.reset_input_buffer()
                ser.reset_output_buffer()
                ser.write(uploadChar)
                read_data = ser.read(96)
            # reading from serial
                # print("reading")
                # print(read_data)
                # read_data = ser.read(96)
            ###########
            # Læs kontinuert efter data er sendt
            # arranger i placering, data, data
                ser.close()
                # app.setLabel("recdata1",
                # bin(read_data[32:63].zfill(flitsize)))
            else:
                app.errorBox(
                    "Error!", "up - Impossible to communicate with the FPGA board on the selected serial port.")

    except:
        app.errorBox(
            "Error!", "up - Impossible to communicate on the selected serial port.")
    # lul = int(read_data[4:8].encode('hex'), 16)
    lul = int.from_bytes(read_data[4:8], byteorder='big')
    datarec1 = bin(lul)[2:].zfill(flitsize)

    lul2 = int.from_bytes(read_data[8:12], byteorder='big')
    datarec2 = bin(lul2)[2:].zfill(flitsize)

    # find destination
    lul3 = int.from_bytes(read_data[0:1], byteorder='big')
    destrec = bin(lul3)[6:10]
    y_dest = int(destrec[0:2], 2)
    x_dest = int(destrec[2:4], 2)
    #print(x_dest, y_dest)
    app.setLabel("dest", "X: " + str(x_dest) + ", Y: " + str(y_dest))
    app.setLabel("recdata1", hex(int(datarec1, 2)))
    app.setLabel("recdata2", hex(int(datarec2, 2)))
    app.setLabelBg("recdata1", "green")
    app.setLabelBg("recdata2", "green")
    app.setLabelBg("dest", "green")
    return


def writeSerial(button):
    dwTh = threading.Thread(target=writeSerialTh)
    dwTh.daemon = True
    dwTh.start()
    return


def bitsting_to_bytes(s):
    return int(s, 2).to_bytes(len(s) // 8, byteorder='big')


def makePacket(button):
    global writeFlits_temp
    global writeFlits
    flitdata1 = int(app.getEntry("flit1ent"), 16)
    flitdata2 = int(app.getEntry("flit2ent"), 16)
    flit1bin = bin(flitdata1)[2:].zfill(flitsize)
    flit2bin = bin(flitdata2)[2:].zfill(flitsize)
    routebin = bin(routing)[2:].zfill(flitsize)

    writeFlits_temp = routebin + flit1bin + flit2bin
    writeFlits = bitsting_to_bytes(writeFlits_temp)
    # print(routebin)
    # print(flit1bin)
    # print(flit2bin)
    # print(writeFlits)
    app.setLabel("route", hex(routing))
    app.setLabel("data1", hex(flitdata1))
    app.setLabel("data2", hex(flitdata2))
    app.enableButton("button_send")
    return
# grid


def button00(button):

    return


def button01(button):
    global routing
    routing = int("00000000000000000000000000001110", 2)
    app.setLabel("selected_dest", "Selected Destination is: 0,1")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button02(button):
    global routing
    routing = int("00000000000000000000000000111010", 2)
    app.setLabel("selected_dest", "Selected Destination is: 0,2")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button03(button):
    global routing
    routing = int("00000000000000000000000000001011", 2)
    app.setLabel("selected_dest", "Selected Destination is: 0,3")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return
# 1


def button10(button):
    global routing
    routing = int("00000000000000000000000001000000", 2)
    app.setLabel("selected_dest", "Selected Destination is: 1,0")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button11(button):
    global routing
    routing = int("00000000000000000000000000000110", 2)
    app.setLabel("selected_dest", "Selected Destination is: 1,1")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button12(button):
    global routing
    routing = int("00000000000000000000000000011010", 2)
    app.setLabel("selected_dest", "Selected Destination is: 1,2")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button13(button):
    global routing
    routing = int("00000000000000000000000000000111", 2)
    app.setLabel("selected_dest", "Selected Destination is: 1,3")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return
# 2


def button20(button):
    global routing
    routing = int("00000000000000000000000000010000", 2)
    app.setLabel("selected_dest", "Selected Destination is: 2,0")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button21(button):
    global routing
    routing = int("00000000000000000000000000010110", 2)
    app.setLabel("selected_dest", "Selected Destination is: 2,1")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button22(button):
    global routing
    routing = int("00000000000000000000000001011010", 2)
    app.setLabel("selected_dest", "Selected Destination is: 2,2")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button23(button):
    global routing
    routing = int("00000000000000000000000000010111", 2)
    app.setLabel("selected_dest", "Selected Destination is: 2,3")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return
# 3


def button30(button):
    global routing
    routing = int("00000000000000000000000000000100", 2)
    app.setLabel("selected_dest", "Selected Destination is: 3,0")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button31(button):
    global routing
    routing = int("00000000000000000000000000111000", 2)
    app.setLabel("selected_dest", "Selected Destination is: 3,1")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button32(button):
    global routing
    routing = int("00000000000000000000000011101000", 2)
    app.setLabel("selected_dest", "Selected Destination is: 3,2")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


def button33(button):
    global routing
    routing = int("00000000000000000000000000010011", 2)
    app.setLabel("selected_dest", "Selected Destination is: 3,3")
    app.enableButton("button_make")
    app.disableButton("button_send")
    return


#############################
# buttons


#############################
# Gui

# create a GUI variable called app
app = gui("Serial interface", "600x600")
app.setFont(10)
# app.setIcon(fileName)
app.setSticky("ew")

row = -1

# Setup serial section
row = row + 1
app.addLabel("label_s_title",
             "Setup serial connection to the FPGA board", row, 0, 4)
app.setLabelAlign("label_s_title", "left")

row = row + 1
app.addLabel("label_s1", "Serial port:", row, 0)
app.setLabelAlign("label_s1", "right")
app.addOptionBox("list_serial_s", ["-No serial ports available-"], row, 1, 2)
app.addNamedButton("Refresh list", "button_s1", refreshSerialList, row, 3)

row = row + 1
app.addLabel("label_s2", "Test serial port:", row, 0)
app.setLabelAlign("label_s2", "right")
app.addEntry("entry_s1", row, 1, 2)
app.setEntry(
    "entry_s1", "Test if the FPGA board is connected to this serial port.", callFunction=False)
app.disableEntry("entry_s1")
app.addNamedButton("Test port", "button_s2", testSerialButton, row, 3)

# Destination section
row = row + 1
app.addHorizontalSeparator(row, 0, 4)
row = row + 1
app.addLabel("label_dest_title", "Select Destination:", row, 0, 4)
app.setLabelAlign("label_dest_title", "left")

row = row + 1
app.addNamedButton("Start", "button_00", button00, row, 0)
app.disableButton("button_00")
app.addNamedButton("0,1", "button_01", button01, row, 1)
app.addNamedButton("0,2", "button_02", button02, row, 2)
app.addNamedButton("0,3", "button_03", button03, row, 3)
row = row + 1
app.addNamedButton("1,0", "button_10", button10, row, 0)
app.addNamedButton("1,1", "button_11", button11, row, 1)
app.addNamedButton("1,2", "button_12", button12, row, 2)
app.addNamedButton("1,3", "button_13", button13, row, 3)
row = row + 1
app.addNamedButton("2,0", "button_20", button20, row, 0)
app.addNamedButton("2,1", "button_21", button21, row, 1)
app.addNamedButton("2,2", "button_22", button22, row, 2)
app.addNamedButton("2,3", "button_23", button23, row, 3)
row = row + 1
app.addNamedButton("3,0", "button_30", button30, row, 0)
app.addNamedButton("3,1", "button_31", button31, row, 1)
app.addNamedButton("3,2", "button_32", button32, row, 2)
app.addNamedButton("3,3", "button_33", button33, row, 3)
row = row + 1
app.addLabel("selected_dest", "Selected Destination is: NONE", row, 0, 4)
app.setLabelAlign("selected_dest", "left")


# Add flits
row = row + 1
app.addHorizontalSeparator(row, 0, 4)
row = row + 1
app.addLabel("addSumFlits",
             "Add Data: (1st Flit is determined by selected destination)", row, 0, 4)
app.setLabelAlign("addSumFlits", "left")
row = row + 1
app.addLabel("flit1", "2nd Flit (hex): ", row, 0)
app.setLabelAlign("flit1", "right")
app.addEntry("flit1ent", row, 1, 2)
row = row + 1
app.addLabel("flit2", "3rd Flit (hex): ", row, 0)
app.setLabelAlign("flit2", "right")
app.addEntry("flit2ent", row, 1, 2)
row = row + 1
app.addNamedButton("Make Packet", "button_make", makePacket, row, 0, 4)
app.disableButton("button_make")
# Connect Data
row = row + 1
app.addHorizontalSeparator(row, 0, 4)
row = row + 1
app.addLabel("complete_data", "Complete packet to be sent to NoC:", row, 0, 4)
app.setLabelAlign("complete_data", "left")
row = row + 1
app.addLabel("routelab", "Route flit", row, 1)
app.addLabel("data1lab", "Data 1 flit", row, 2)
app.addLabel("data2lab", "Data 2 flit", row, 3)
row = row + 1
app.addLabel("datalabel", "Flit data: ", row, 0)
app.addLabel("route", "NONE", row, 1)
app.addLabel("data1", "NONE", row, 2)
app.addLabel("data2", "NONE", row, 3)
row = row + 1
app.addNamedButton("Send Data", "button_send", writeSerial, row, 0, 4)

app.disableButton("button_send")

row = row + 1
app.addHorizontalSeparator(row, 0, 4)
row = row + 1
app.addLabel("recieved_data", "Packet recieved from NoC", row, 0, 4)
app.setLabelAlign("recieved_data", "left")
row = row + 1
app.addLabel("destlab", "Destination at: ", row, 1)
app.addLabel("data1reclab", "Data 1 flit recieved", row, 2)
app.addLabel("data2reclab", "Data 2 flit recieved", row, 3)
row = row + 1
app.addLabel("resultlabel", "Result: ", row, 0)
app.addLabel("dest", "NONE", row, 1)
app.addLabel("recdata1", "NONE", row, 2)
app.addLabel("recdata2", "NONE", row, 3)
row = row + 1
app.addHorizontalSeparator(row, 0, 4)

# done
refreshSerialList(None)
app.registerEvent(updateTestLabel)

app.setResizable(False)
app.go()
