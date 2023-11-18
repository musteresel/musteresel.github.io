---
title: Bug in CyBle_GapSetLocalName PSoC4 generated BLE API function
tags: [c, embedded]
date: 2023-06-29
language: en
...

I'm using a PSoC4 BLE module from Cypress / Infineon, and have defined the configuration of the BLE subsystem via the PSoC Creator BLE component. This includes a setting for the "local name" of the device, which will be accessible as "Device name" characteristic (UUID 0x2A00) in the "Generic Access Service" (UUID 0x1800).

The PSoC Creator component creates, in the end, a big data structure (called `cyBle_gattDB`) with memory for every characteristic and their values. As this data structure is static, the length of a characteristic (that is, the number of bytes its value needs) cannot increase at runtime. The data structure however also stores the actual length of each characteristic, meaning that the length of a characteristic can be reduced at runtime. Or put differently, the length which is chosen via the PSoC Creator component configuration is actually the maximum length of the respective characteristic.

In my case I need to change the device name at runtime, after learning some facts about the runtime environment. Therefore, I set the local name in the component configuration dialog to a long(er) placeholder value ("xxxxxxxx" for example) and update the value shortly after reset in `main`.

For that, I initially used `CyBle_GapSetLocalName` which is a function from `Generated_Source/PSoC4/BLE.c`:

~~~c
    /******************************************************************************
    * Function Name: CyBle_GapSetLocalName
    ***************************************************************************//**
    *  This function is used to set the local device name - a Characteristic of the 
    *  GAP Service. If the characteristic length entered in the component customizer
    *  is shorter than the string specified by the "name" parameter, the local device
    *  name will be cut to the length specified in the customizer.
    * 
    *  \param name: The local device name string. The name string to be written as
    *              the local device name. It represents a UTF-8 encoded User
    *              Friendly Descriptive Name for the device. The length of the local
    *              device string is entered into the component customizer and it can
    *              be set to a value from 0 to 248 bytes. If the name contained in
    *              the parameter is shorter than the length from the customizer, the
    *              end of the name is indicated by a NULL octet (0x00).
    * 
    * \return
    *  CYBLE_API_RESULT_T : Return value indicates if the function succeeded or 
    *  failed. Following are the possible error codes.
    *
    *   Errors codes                       | Description
    *   ------------                       | -----------
    *   CYBLE_ERROR_OK                     | Function completed successfully.
    *   CYBLE_ERROR_INVALID_PARAMETER      | On specifying NULL as input parameter
    *  
    *******************************************************************************/
    CYBLE_API_RESULT_T CyBle_GapSetLocalName(const char8 name[])
    { // ... function body ...
~~~


Unfortunately, even though the function body contains a comment declaring ...

~~~c
/* Set new actual length */
~~~

... **it does not actually do that!** So if I change the name to "Jon" via that function, the characteristic will contain the value

~~~c
"Jon\0xxxx"
~~~

So, the string "Jon" including its terminating null character, followed by the rest of the placeholder string. This behaviour is also somewhat explained by the function documentation.

Interestingly, it is also not possible to adjust the length of the characteristic using the "standard" function to set attribute values, `CyBle_GattsWriteAttributeValue`:

~~~c
attributeValue.attrHandle = 3; // handle of local device name!
attributeValue.value.val = (uint8_t * const) new_name;
attributeValue.value.len = strlen(new_name);
uint8_t flag = CYBLE_GATT_DB_LOCALLY_INITIATED;
CyBle_GattsWriteAttributeValue(&attributeValue, 0, &cyBle_connHandle, flag); // DOES NOT CHANGE LENGTH!
~~~

**However, it is possible to adjust the actual length of a characteristic value using:**

~~~c
CYBLE_GATT_DB_ATTR_SET_ATTR_GEN_LEN(3, strlen(new_name));
// 3 == handle of local device name == cyBle_gaps.deviceNameCharHandle
~~~


I've also written about this in the [Infineon developer forum](https://community.infineon.com/t5/AIROC-Bluetooth/Set-BLE-local-name-to-shorter-name/m-p/450873#M4101). There's also [an older post](https://community.infineon.com/t5/PSoC-4/CyBle-GapSetLocalName-doesn-t-affect-Device-Name-characteristic/m-p/177239#M27232), which I've found somewhat later, which describes a similar way using the "get" variant of above macro.
