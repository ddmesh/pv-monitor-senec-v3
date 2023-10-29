#!/bin/bash

# das script ruft senec pv analage werte ab, nutzt javascript command line interpeter (jsc)
# um die senec werte zu dekotieren (das script habe ich direkt senec Geraet).
# Die daten werden alle paar sekunden an die Datenbank geschickt

SENEC_IP="192.168.2.107"


while sleep 5
do

# java script interpeter 'jsc'
#
# apt install libjavascriptcoregtk-4.0-bin curl jq

json=$(curl -s -o - -X POST http://${SENEC_IP}/lala.cgi \
        --header 'Accept: application/json' \
        --header 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
        --data-raw '{"RTC":{"WEB_TIME":""},
	             "ENERGY":{"STAT_STATE":"",
                      "GUI_INVERTER_POWER":"","GUI_HOUSE_POW":"","GUI_GRID_POW":"",
                      "GUI_BAT_DATA_CURRENT":"",
		      "GUI_BAT_DATA_FUEL_CHARGE":"",
		      "GUI_BAT_DATA_POWER":"",
		      "GUI_BAT_DATA_VOLTAGE":"",
		      "GUI_CHARGING_INFO":"",
		      "GUI_BOOSTING_INFO":""},
                     "PM1OBJ1":{"FREQ":"", "U_AC":["","",""], "I_AC":["","",""], "P_AC":["","",""], "P_TOTAL":""},
                     "PM1OBJ2":{"FREQ":"", "U_AC":["","",""], "I_AC":["","",""], "P_AC":["","",""], "P_TOTAL":""},
                     "BAT1OBJ1":{"TEMP1":"","TEMP2":"", "I_DC":""},
                     "PV1":{"MPP_CUR":["","",""], "MPP_POWER":["","",""],  "MPP_VOL":["","",""] }
                                         }')
echo $json | jq
echo "x---------------------------------------"

function decode()
{
    value="$1"

   # jse -e 'script' -- arg1 arg2,....
   # argumente werden als array bereitgestellt mit namen "arguments"
    jsc -e "

    function _hex2float(num)
    {
        var sign = (num & 0x80000000) ? -1 : 1;
        var exponent = ((num >> 23) & 0xff) - 127;
        var mantissa = ((num & 0x7fffff) + 0x800000).toString(2); // binary
        var float = 0;
        // Convert to float
        for (var i=0; i<mantissa.length; i+=1)
        {
            float += parseInt(mantissa[i])? Math.pow(2,exponent):0;
            exponent--;
        }
        return sign * float;
    }

    function _hex2dec(num)
    {
    return parseInt(num, 16);
    }

    function jsonValUnpack(data)
    {
        var tmp = data.split('_');
        var value = tmp[1];
        switch (tmp[0])
        {
            case 'fl':
                value = _hex2float('0x' + value);
                value = Math.round(value * 100) / 100;
                break;
            case 'u8':
                //alert('u8');
                value = _hex2dec(value);
                if (value < 10)
                {
                    value = '0' + value;
                }
                break;
            case 'u1':
                //alert('u1');
                value = _hex2dec(value);
                if (value < 10)
                {
                    value = '0' + value;
                }
                break;
            case 'u3':
                value = _hex2dec(value);
                break;
            case 'u6':
                value = _hex2dec(value);
                break;
            case 'i1':
                value = parseInt(value, 16);

                if(!isNaN(value)) {
                    if (value < 10) {
                        value = '0' + value;
                    }
                    if ((value & 0x8000) > 0) {
                        value = value - 0x10000;
                    }
                }
                else  {
                    value = NaN;
                }
                break;
            case 'i3':
                value = parseInt(value, 16);
                if(!isNaN(value))
                {
                    if (value < 10) {
                        value = '0' + value;
                    }

                    if ((Math.abs(value & 0x80000000)) > 0) {
                        value = value - 0x100000000;
                    }
                }
                else  {
                    value = NaN;
                }

                break;
            case 'i8':
                value = parseInt(value, 16);
                if (value < 10) {
                    value = '0' + value;
                }
                if ((value & 0x80) > 0) {
                    value = value - 0x100;
                }
                break;
            case 'ch':
                //alert('ch');
                break;
            case 'st':
                //alert('st');
                value = data.substr(3);
                break;
            case 'er':
                console.log('error: ' + data);
                break;
            default:
                console.log('error: unknown variable type: ' + data);
                value = data;
                break;
        }
        return value;
    }


    //print(arguments[0])
    print(jsonValUnpack(arguments[0]));
    " -- ${value}
}



if [ -n "$json" ]; then
    eval $(echo $json | jq --raw-output  '"time=\"\(.RTC.WEB_TIME)\";
             state=\"\(.ENERGY.STAT_STATE)\";
             pwr_bat=\"\(.ENERGY.GUI_BAT_DATA_POWER)\";
             pwr_pv=\"\(.ENERGY.GUI_INVERTER_POWER)\";
             pwr_house=\"\(.ENERGY.GUI_HOUSE_POW)\";
             pwr_grid=\"\(.ENERGY.GUI_GRID_POW)\";
             bat_fuel=\"\(.ENERGY.GUI_BAT_DATA_FUEL_CHARGE)\";
             bat_u=\"\(.ENERGY.GUI_BAT_DATA_VOLTAGE)\";
             bat_i=\"\(.ENERGY.GUI_BAT_DATA_CURRENT)\";
             charging_info=\"\(.ENERGY.GUI_CHARGING_INFO)\";
             bat1_iDC=\"\(.BAT1OBJ1.I_DC)\";
             bat1_temp1=\"\(.BAT1OBJ1.TEMP1)\";
             bat1_temp2=\"\(.BAT1OBJ1.TEMP2)\";
             wr1_freq=\"\(.PM1OBJ1.FREQ)\";
             wr1_L1_u=\"\(.PM1OBJ1.U_AC[0])\";
             wr1_L2_u=\"\(.PM1OBJ1.U_AC[1])\";
             wr1_L3_u=\"\(.PM1OBJ1.U_AC[2])\";
             wr1_L1_i=\"\(.PM1OBJ1.I_AC[0])\";
             wr1_L2_i=\"\(.PM1OBJ1.I_AC[1])\";
             wr1_L3_i=\"\(.PM1OBJ1.I_AC[2])\";
             wr1_L1_p=\"\(.PM1OBJ1.P_AC[0])\";
             wr1_L2_p=\"\(.PM1OBJ1.P_AC[1])\";
             wr1_L3_p=\"\(.PM1OBJ1.P_AC[2])\";
             wr1_ptotal=\"\(.PM1OBJ1.P_TOTAL)\";
             mpp1_u=\"\(.PV1.MPP_VOL[0])\";
             mpp2_u=\"\(.PV1.MPP_VOL[1])\";
             mpp3_u=\"\(.PV1.MPP_VOL[2])\";
             mpp1_i=\"\(.PV1.MPP_CUR[0])\";
             mpp2_i=\"\(.PV1.MPP_CUR[1])\";
             mpp3_i=\"\(.PV1.MPP_CUR[2])\";
             mpp1_p=\"\(.PV1.MPP_POWER[0])\";
             mpp2_p=\"\(.PV1.MPP_POWER[1])\";
             mpp3_p=\"\(.PV1.MPP_POWER[2])\";
             "')


    time=$(decode ${time})
    state=$(decode ${state})
    pwr_bat=$(decode ${pwr_bat})
    pwr_pv=$(decode ${pwr_pv})
    pwr_house=$(decode ${pwr_house})
    pwr_grid=$(decode ${pwr_grid})


    charging_info=$(decode ${charging_info})
    bat_fuel=$(decode ${bat_fuel})
    bat_u=$(decode ${bat_u})
    bat_i=$(decode ${bat_i})
    bat1_iDC=$(decode ${bat1_iDC})
    bat1_temp1=$(decode ${bat1_temp1})
    bat1_temp2=$(decode ${bat1_temp2})

    wr1_freq=$(decode ${wr1_freq})
    wr1_L1_u=$(decode ${wr1_L1_u})
    wr1_L2_u=$(decode ${wr1_L2_u})
    wr1_L3_u=$(decode ${wr1_L3_u})
    wr1_L1_i=$(decode ${wr1_L1_i})
    wr1_L2_i=$(decode ${wr1_L2_i})
    wr1_L3_i=$(decode ${wr1_L3_i})
    wr1_L1_p=$(decode ${wr1_L1_p})
    wr1_L2_p=$(decode ${wr1_L2_p})
    wr1_L3_p=$(decode ${wr1_L3_p})
    wr1_ptotal=$(decode ${wr1_ptotal})

    mpp1_u=$(decode ${mpp1_u})
    mpp2_u=$(decode ${mpp2_u})
    mpp3_u=$(decode ${mpp3_u})
    mpp1_i=$(decode ${mpp1_i})
    mpp2_i=$(decode ${mpp2_i})
    mpp3_i=$(decode ${mpp3_i})
    mpp1_p=$(decode ${mpp1_p})
    mpp2_p=$(decode ${mpp2_p})
    mpp3_p=$(decode ${mpp3_p})

    # senec liefert falsche zeit, damit werden die daten nicht in graphite ordentlich eingefuegt
    time="$(date +%s)"
    echo "==================================================="
    echo "time: $time $(date -d @$time -u)"
    echo "state: $state"
    echo "PWR PV: $pwr_pv W"
    echo "PWR House: $pwr_house W"
    echo "Charging Info: $charging_info"
    echo "fuel: $bat_fuel %"
    echo "PWR Grid: $pwr_grid W"
    echo "PWR Bat: $pwr_bat W"
    echo "Bat V: $bat_u W"
    echo "Bat I: $bat_i A"
    echo "PWR Bat: $pwr_bat W"
    echo "bat1 I DC: $bat1_iDC A"
    echo "bat1 temp1: $bat1_temp1 Grad"
    echo "bat1 temp2: $bat1_temp2 Grad"

    echo "wr1 freq:$wr1_freq Hz"
    printf "wr1 U: %6s V | %6s V | %6s V\n" $wr1_L1_u $wr1_L2_u $wr1_L3_u
    printf "wr1 I: %6s A | %6s A | %6s A\n" $wr1_L1_i $wr1_L2_i $wr1_L3_i
    printf "wr1 P: %6s W | %6s W | %6s W\n" $wr1_L1_p $wr1_L2_p $wr1_L3_p
    echo "wr1 P Total:$wr1_ptotal W"

    printf "MPP 1: %6s | %6s | %6s\n" $mpp1_u $mpp1_i $mpp1_p
    printf "MPP 2: %6s | %6s | %6s\n" $mpp2_u $mpp2_i $mpp2_p
    printf "MPP 3: %6s | %6s | %6s\n" $mpp3_u $mpp3_i $mpp3_p

    data=""
    data="${data}senec.state $state $time\n"
    data="${data}senec.power.pv $pwr_pv $time\n"
    data="${data}senec.power.house $pwr_house $time\n"
    data="${data}senec.power.grid $pwr_grid $time\n"
    data="${data}senec.power.bat $pwr_bat $time\n"
    data="${data}senec.charging_info $charging_info $time\n"
    data="${data}senec.bat.fuel $bat_fuel $time\n"
    data="${data}senec.bat.voltage $bat_u $time\n"
    data="${data}senec.bat.current $bat_i $time\n"
    data="${data}senec.bat1.dc_current $bat1_iDC $time\n"
    data="${data}senec.bat1.temp1 $bat1_temp1 $time\n"
    data="${data}senec.bat1.temp2 $bat1_temp2 $time\n"
    data="${data}senec.converter1.freq $wr1_freq $time\n"
    data="${data}senec.converter1.power_total $wr1_ptotal $time\n"
    data="${data}senec.converter1.L1.voltage $wr1_L1_u $time\n"
    data="${data}senec.converter1.L2.voltage $wr1_L2_u $time\n"
    data="${data}senec.converter1.L3.voltage $wr1_L3_u $time\n"
    data="${data}senec.converter1.L1.current $wr1_L1_i $time\n"
    data="${data}senec.converter1.L2.current $wr1_L2_i $time\n"
    data="${data}senec.converter1.L3.current $wr1_L3_i $time\n"
    data="${data}senec.converter1.L1.power $wr1_L1_p $time\n"
    data="${data}senec.converter1.L2.power $wr1_L2_p $time\n"
    data="${data}senec.converter1.L3.power $wr1_L3_p $time\n"
    data="${data}senec.mpp1.voltage $mpp1_u $time\n"
    data="${data}senec.mpp2.voltage $mpp2_u $time\n"
    data="${data}senec.mpp3.voltage $mpp3_u $time\n"
    data="${data}senec.mpp1.current $mpp1_i $time\n"
    data="${data}senec.mpp2.current $mpp2_i $time\n"
    data="${data}senec.mpp3.current $mpp3_i $time\n"
    data="${data}senec.mpp1.power $mpp1_p $time\n"
    data="${data}senec.mpp2.power $mpp2_p $time\n"
    data="${data}senec.mpp3.power $mpp3_p $time\n"

    # data="${data}senec.random $((RANDOM % 100)) $time\n"

    #printf "$data"
		# alternativ "netcat" statt "nc"
    printf "${data}" | nc -w3 127.0.0.1 2003

else
    echo "connection error"
fi


done
