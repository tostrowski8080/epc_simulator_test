*** Settings ***
Documentation    EPC Simulator — 4 test cases covering reset, showing traffic stats, attach/detach and adding bearer.
Library          EpcSimulatorLibrary.py    base_url=http://localhost:8000
Library          Collections
Test Setup       Reset Simulator

*** Variables ***
${UE_1}              1
${UE_2}              2
${BEARER_DEFAULT}    9
${BEARER_1}          1
${MIN_UE}            0
${MAX_UE}            100
${MIN_BEARER}        1
${MAX_BEARER}        9

*** Test Cases ***

Reset Clears All UEs And Bearers
    [Documentation]    After attaching two UEs and triggering reset, the simulator
    ...                should return to a default state with no UEs present.
    [Tags]    reset
    Attach UE    ${UE_1}
    Attach UE    ${UE_2}
    ${before}=    List UEs
    Length Should Be    ${before}    2
    Reset Simulator
    ${after}=    List UEs
    Length Should Be    ${after}    0

Traffic Stats Reflect Started Transfer
    [Documentation]    After starting 50 Mbps traffic on the default bearer, the stats
    ...                endpoint should report target_bps equal to 52 428 800.
    [Tags]    stats
    Attach UE    ${UE_1}
    Start Traffic    ${UE_1}    ${BEARER_DEFAULT}    protocol=udp    mbps=50
    ${stats}=    Get Traffic Stats    ${UE_1}    ${BEARER_DEFAULT}
    Should Be Equal As Integers    ${stats}[target_bps]    50000000

Attach And Detach UE
    [Documentation]    A UE can be attached and then successfully detached.
    ...                After detach it must no longer appear in the UE list.
    [Tags]    attach    detach
    Attach UE    ${UE_1}
    ${list_after_attach}=    List UEs
    Should Contain    ${list_after_attach}    ${1}
    Detach UE    ${UE_1}
    ${list_after_detach}=    List UEs
    Should Not Contain    ${list_after_detach}    ${1}

Add And Delete Bearer
    [Documentation]    A bearer can be added to an attached UE and then removed.
    ...                After deletion only the default bearer (9) should remain.
    [Tags]    bearer
    Attach UE    ${UE_1}
    Add Bearer    ${UE_1}    ${BEARER_1}
    ${ue_after_add}=    Get UE    ${UE_1}
    Dictionary Should Contain Key      ${ue_after_add}[bearers]    1
    Delete Bearer    ${UE_1}    ${BEARER_1}
    ${ue_after_del}=    Get UE    ${UE_1}
    Dictionary Should Not Contain Key    ${ue_after_del}[bearers]    1
    Dictionary Should Contain Key        ${ue_after_del}[bearers]    9


Check Active Bearers For UE
    [Documentation]    After attach, UE should have only the default bearer (9).
    ...                After adding bearer 1, both bearers should be listed.
    [Tags]    bearer
    Attach UE    ${UE_1}
    ${ue}=    Get UE    ${UE_1}
    Dictionary Should Contain Key      ${ue}[bearers]    9
    Length Should Be    ${ue}[bearers]    1
    Add Bearer    ${UE_1}    ${BEARER_1}
    ${ue}=    Get UE    ${UE_1}
    Dictionary Should Contain Key      ${ue}[bearers]    1
    Dictionary Should Contain Key      ${ue}[bearers]    9
    Length Should Be    ${ue}[bearers]    2

Attach UEs At Boundary IDs
    [Documentation]    UE IDs have a range of (0-100),
    ...                IDs on the edges should attach correctly.
    [Tags]    attach    boundary
    Attach UE    ${MAX_UE}
    Attach UE    ${MIN_UE}
    ${ues}=    List UEs
    Length Should Be    ${ues}    2

Cannot Attach UEs Outside ID Range
    [Documentation]    UE IDs have a range of (0-100), attempting to attach
    ...                IDs outside of the range should return error.
    [Tags]    attach    boundary
    Run Keyword And Expect Error    *HTTPError*    Attach UE    ${{ ${MIN_UE} - 1 }}
    Run Keyword And Expect Error    *HTTPError*    Attach UE    ${{ ${MAX_UE} + 1 }}

Add Bearer At Boundary IDs
    [Documentation]    Bearer IDs have a range of (1-9).
    ...                IDs on the edges should attach correctly.
    ...                If one of the edge bearers is the default one, skips it.
    [Tags]    bearer    boundary
    Attach UE    ${UE_1}
    IF    ${MIN_BEARER} != ${BEARER_DEFAULT}
        Add Bearer    ${UE_1}    ${MIN_BEARER}
    END
    IF    ${MAX_BEARER} != ${BEARER_DEFAULT}
        Add Bearer    ${UE_1}    ${MAX_BEARER}
    END
    ${ue}=    Get UE    ${UE_1}
    Dictionary Should Contain Key    ${ue}[bearers]    ${MIN_BEARER}
    Dictionary Should Contain Key    ${ue}[bearers]    ${MAX_BEARER}

Cannot Add Bearer Outside ID Range
    [Documentation]    Bearer IDs have a range of (1-9), attempting to add
    ...                IDs outside of the range should return error.
    [Tags]    bearer    boundary
    Attach UE    ${UE_1}
    Run Keyword And Expect Error    *HTTPError*    Add Bearer    ${UE_1}    ${{ ${MIN_BEARER} - 1 }}
    Run Keyword And Expect Error    *HTTPError*    Add Bearer    ${UE_1}    ${{ ${MAX_BEARER} + 1 }}

Start And Stop Traffic
    [Documentation]    Traffic can be started and stopped.
    ...                After stopping duration from stats should stop increasing.
    [Tags]    traffic
    Attach UE    ${UE_1}
    Start Traffic    ${UE_1}    ${BEARER_DEFAULT}    protocol=udp    mbps=50
    ${stop_resp}=    Stop Traffic    ${UE_1}    ${BEARER_DEFAULT}
    Dictionary Should Contain Item    ${stop_resp}    status    traffic_stopped
    ${stats_before}=    Get Traffic Stats    ${UE_1}    ${BEARER_DEFAULT}
    Sleep    1s
    ${stats_after}=    Get Traffic Stats    ${UE_1}    ${BEARER_DEFAULT}
    Should Be Equal    ${stats_before}[duration]    ${stats_after}[duration]

Traffic Duration Keeps Increasing
    [Documentation]    Starts traffic and verifies that the duration
    ...                from stats increases over time.
    [Tags]    traffic
    Attach UE    ${UE_1}
    Start Traffic    ${UE_1}    ${BEARER_DEFAULT}    protocol=udp    mbps=50
    ${stats_before}=    Get Traffic Stats    ${UE_1}    ${BEARER_DEFAULT}
    Sleep    1s
    ${stats_after}=    Get Traffic Stats    ${UE_1}    ${BEARER_DEFAULT}
    Should Be True    ${stats_after}[duration] > ${stats_before}[duration]
    Stop Traffic    ${UE_1}    ${BEARER_DEFAULT}
