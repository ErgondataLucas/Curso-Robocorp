*** Settings ***
Documentation       Encomenda robôs da RobotSpareBin Industries Inc.
...                 Salva os reicbos HTML do pedido como PDF.
...                 Salva um screenshot do robo solicitado.
...                 incorpora o screenshotdo robô ao recibo em PDF.
...                 Cria um ZIP dos recibos e das imagens

Library             RPA.HTTP
Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.PDF
Library             OperatingSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${Temp_dir}     ${OUTPUT_DIR}${/}Temp


*** Tasks ***
Realizar e salvar pedidos de robos
    ${download} =    Obter URL dos pedidos
    ${site} =    Get Secret    PedidosRobo

    Criar diretorios
    Download csv    ${download}
    Acessar site    ${site}
    Realizar pedidos
    Zip pasta


*** Keywords ***
Obter URL dos pedidos
    Add text input    pedido    label=Insira URL do Pedido
    ${download} =    Run dialog

    RETURN    ${download.pedido}

Criar diretorios
    Create Directory    ${Temp_dir}

Download csv
    [Arguments]    ${pedidos}

    Download    ${pedidos}    overwrite=True

Acessar site
    [Arguments]    ${site}

    Open Available Browser    ${site}[URL]

Realizar pedidos
    ${orders} =    Read table from CSV    orders.csv    delimiters=,

    FOR    ${order}    IN    @{orders}
        Preencher formulario    ${order}
        Obter screenshot    ${order}
        Enviar pedido e obter dados do pedido    ${order}
        Incorpora imagem ao pdf    ${order}
    END

Preencher formulario
    [Arguments]    ${order}

    Wait Until Page Contains Element    css:.btn-dark
    Click Button    css:.btn-dark
    Select From List By Index    css:#head    ${order}[Head]
    Click Button    id-body-${order}[Body]
    Input Text    class:form-control    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

    Click Button    id:preview
    Wait Until Page Contains Element    robot-preview-image

Obter screenshot
    [Arguments]    ${order}

    Screenshot    robot-preview-image    filename=${Temp_dir}${/}screenshot_${order}[Order number].png

Enviar pedido e obter dados do pedido
    [Arguments]    ${order}

    ${teste} =    Set Variable    ${False}

    WHILE    ${teste} == False
        Click Button    id:order
        ${teste} =    Run Keyword And Return Status    Wait Until Page Contains Element    id:receipt
    END
    ${element_html} =    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${element_html}    ${Temp_dir}${/}order_${order}[Order number].pdf
    Click Button    id:order-another

Incorpora imagem ao pdf
    [Arguments]    ${order}

    @{files} =    Create List
    ...    ${Temp_dir}${/}order_${order}[Order number].pdf
    ...    ${Temp_dir}${/}screenshot_${order}[Order number].png:align=center
    Add Files To Pdf    ${files}    ${Temp_dir}${/}Pedido_${order}[Order number].pdf:0

Zip pasta
    ${Zip} =    Set Variable    ${OUTPUT_DIR}${/}Pedidos.Zip
    Archive Folder With Zip    ${Temp_dir}    ${Zip}
