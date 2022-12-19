*** Settings ***
Documentation       Solving problems for part 2 of training

Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.Robocorp.Vault
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open website
    ${orders}=    Download file and extract table
    FOR    ${order}    IN    @{orders}
        Close modal window
        Fill the form    ${order}
        Get Preview
        Submit Order
        Get PDF File    ${OUTPUT_DIR}${/}pdfs${/}${order}[Order number].pdf
        Make Screenshot
        Embed screnshot    ${OUTPUT_DIR}${/}pdfs${/}${order}[Order number].pdf    ${OUTPUT_DIR}${/}robot.png
        Order another
    END
    Create ZIP package from PDF files


*** Keywords ***
Open website
    ${secret}=    Get Secret    website
    ${website_link}=    Set Variable    ${secret}[link]
    Open Available Browser    ${website_link}

#https://robotsparebinindustries.com/#/robot-order

#https://robotsparebinindustries.com/orders.csv

Download file and extract table
    Add heading    Gimme the link for the file plz
    Add text input    link    label=Data file link:
    ${result}=    Run dialog
    ${file_link}=    Set Variable    ${result.link}
    Download    ${file_link}    overwrite=True
    ${orders}=    Read table from CSV    path=orders.csv    header=${True}
    RETURN    ${orders}

Close modal window
    Wait Until Element Is Visible    class:alert-buttons
    Click Button    I guess so...

Fill the form
    [Arguments]    ${row}
    Select From List By Value    name=head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    #class:input.form-control[type="number"]
    Input Text
    ...    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    ...    ${row}[Legs]
    Input Text    id=address    ${row}[Address]

Get Preview
    Wait Until Keyword Succeeds    10x    1 sec    Assert Robot Image is there

Submit Order
    Wait Until Keyword Succeeds    5x    1 sec    Assert Robot Receipt is there

Get PDF File
    [Arguments]    ${path}
    Wait Until Element Is Visible    id=receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${path}

Make Screenshot
    Screenshot    id=robot-preview-image    filename=${OUTPUT_DIR}${/}robot.png

Embed screnshot
    [Arguments]    ${receipt_path}    ${screenshot_path}
    #Open Pdf    ${receipt_path}
    #Set Field Value    pic    ${screenshot_path}
    #Save Field Values    ${receipt_path}
    ${files}=    Create List    ${screenshot_path}
    Add Files To Pdf    files=${files}    target_document=${receipt_path}    append=${True}

Order another
    Wait Until Keyword Succeeds    3x    3 sec    Assert order is gone

Assert order is gone
    Click Button    order-another
    Wait Until Element Is Not Visible    order-another

Assert Robot Image is there
    Click Button    Preview
    Wait Until Element Is Visible    id=robot-preview-image

Assert Robot Receipt is there
    Click Button    order
    Wait Until Element Is Visible    id=receipt

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}pdfs
    ...    ${zip_file_name}
