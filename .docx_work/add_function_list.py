from pathlib import Path

from docx import Document
from docx.enum.section import WD_ORIENT, WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor


SOURCE = Path(r"C:\Users\BeeNaa\Downloads\Telegram Desktop\KhmerStay_Project_Requirements (3).docx")
OUTPUT = Path(r"C:\Users\BeeNaa\Downloads\Telegram Desktop\KhmerStay_Project_Requirements_With_Function_List.docx")


api_rows = [
    ("System and runtime", "Service startup and health", "Start the Go HTTP service, load environment settings, expose the health check, apply CORS rules, decode requests, and return consistent JSON responses and errors.", "Implemented"),
    ("Data storage", "SQLite persistence", "Create and seed tables for users, sessions, OTP records, properties, rooms, bookings, payments, favorites, conversations, messages, reviews, notifications, blocked dates, promotions, settings, and audit logs.", "Implemented"),
    ("Authentication", "Accounts and sessions", "Register traveler or owner accounts, sign in with email and password, create seven-day sessions, return the signed-in user, sign out, hash passwords with bcrypt, and enforce role-based access.", "Implemented"),
    ("Email OTP", "Verification and recovery", "Generate random six-digit codes, store only hashed codes, enforce expiry, resend delay and attempt limits, verify registration or email sign-in, and reset passwords through SMTP delivery.", "Implemented; SMTP account required for external email"),
    ("Property catalog", "Browse and filter stays", "List published properties for travelers; expose owner and administrator records according to access; filter by search text, province, category and status; return property details.", "Implemented"),
    ("Property management", "Listings and rooms", "Create owner listings, edit permitted property fields, store room types and inventory, submit a listing for review, and let administrators publish, reject, pause or restore listings.", "Implemented"),
    ("Image storage", "Property photo upload", "Accept authenticated PNG, JPEG and WebP uploads up to 8 MB, save files in local storage, and serve uploaded images from the API.", "Implemented"),
    ("Booking", "Reservation creation", "Validate dates and guest capacity, check blocked dates and room inventory, calculate the stay total, create a booking reference, create its payment record, and open the related conversation.", "Implemented"),
    ("Booking", "Reservation lifecycle", "List role-scoped bookings, return booking details, enforce traveler, owner and administrator permissions, and validate cancellation, confirmation, check-in, completion, decline and no-show transitions.", "Implemented"),
    ("KHQR payment", "QR generation and verification", "Generate a transaction-specific KHQR payload and QR image, store its MD5 and expiry, check payment through the Bakong API, match account, currency and amount, then confirm the booking after verification.", "Implemented; Bakong account and token required"),
    ("KHQR payment", "Local payment demonstration", "Allow a traveler to confirm a pending payment in development when Bakong is not configured; disable this route outside development and when a receiving account is configured.", "Development fallback"),
    ("Favorites", "Saved properties", "List, add and remove a traveler's favorite published properties.", "Implemented"),
    ("Messaging", "Owner and traveler conversations", "List authorized conversations, retrieve messages, create a conversation when needed, send text messages, enforce participant access, and notify the recipient.", "Implemented"),
    ("Notifications", "In-app updates", "Create booking, payment, message and review notifications; list notifications for the signed-in user; mark an individual notification as read.", "Implemented"),
    ("Reviews", "Guest reviews and owner responses", "List reviews by property, allow a traveler with a completed stay to submit a 1-5 rating and comment, and allow the property owner or administrator to publish a response.", "Implemented"),
    ("Availability", "Blocked date management", "List blocked dates by owner or property and allow an authorized owner or administrator to block or unblock a valid calendar date.", "Implemented"),
    ("Administration", "Operations and configuration", "Return role-based dashboard totals, list users, suspend or reactivate accounts, read and update approved platform settings, create promotions, and record audit events.", "Implemented"),
]


mobile_rows = [
    ("Application startup", "Launch and navigation", "Display splash, onboarding, preference setup, role selection and welcome screens; route users into traveler or owner navigation with animated page transitions.", "Implemented"),
    ("Preferences", "Language and currency", "Switch between Khmer and English, select USD or KHR display, and retain onboarding, language, currency and role preferences locally.", "Implemented locally"),
    ("Authentication", "Account access", "Sign in with password, register a traveler or owner, request and verify an email OTP, sign in by OTP, reset a password, restore the API session, sign out, and require sign-in when switching roles.", "API integrated"),
    ("Traveler discovery", "Explore and search", "Load published properties from the API, browse categories, search destinations, filter results, and open stay details.", "API integrated"),
    ("Traveler discovery", "Property information", "Show property description, room choices, prices, amenities, photo gallery, host profile and guest reviews; load uploaded images from the local API.", "API integrated"),
    ("Favorites", "Wishlist", "Add or remove published properties from favorites and load the signed-in traveler's saved list.", "API integrated"),
    ("Booking", "Reservation flow", "Select a room, choose future dates, set guest count, enter guest details, review the API-aligned total, accept the booking conditions, and create a reservation.", "API integrated"),
    ("Payment", "KHQR checkout", "Display the booking amount and payment state, show the generated KHQR image when configured, request Bakong payment verification, or use the labeled local demonstration confirmation.", "API integrated; credentials required for real payment"),
    ("Trips", "Booking history and status", "Load traveler bookings, group active and past trips, open booking details, and request an allowed cancellation.", "API integrated"),
    ("Messaging", "Inbox and chat", "Load conversations and messages for the signed-in account, open a booking conversation, send text messages, and refresh the conversation state.", "API integrated"),
    ("Reviews", "Ratings and responses", "Load property reviews, allow eligible travelers to submit a rating and comment, and let owners read reviews and save or edit a public response.", "API integrated"),
    ("Notifications", "Updates", "Load API notifications, display unread state, mark a notification as read, and open notification-related content.", "API integrated"),
    ("Traveler account", "Profile and preferences", "Display traveler account options, update app language and currency, access notifications and information screens, switch to owner sign-in, and sign out.", "Partly local; authentication is API integrated"),
    ("Owner dashboard", "Operational summary", "Show owner properties, bookings and revenue summaries using the application state loaded from the API.", "API-backed summary"),
    ("Owner bookings", "Reservation operations", "List owner bookings, inspect guest and stay details, and apply allowed confirmation, decline, check-in and completion transitions.", "API integrated"),
    ("Owner properties", "Listing creation and photos", "List owner properties, open listing details, create or edit a property, upload a photo, and submit listing information to the API.", "API integrated"),
    ("Owner inventory", "Rooms and pricing", "Load each property's room types, add or edit room name, bed, capacity, price and inventory, and save nightly price changes.", "API integrated"),
    ("Owner availability", "Calendar", "Select an owner property, view current and future dates, see bookings that cover a selected date, and block or unblock availability.", "API integrated"),
    ("Owner secondary screens", "Earnings verification and help", "Present earnings, verification and help content for the school demonstration without external payout, identity verification or support services.", "Demonstration UI"),
]


website_rows = [
    ("Authentication", "Owner and administrator access", "Sign in through the Go API, store the session, validate the session with the current-user endpoint, enforce owner or administrator portal access, reset passwords by email OTP, and sign out.", "API integrated"),
    ("Portal shell", "Navigation and preferences", "Provide responsive owner and administrator navigation, global search, Khmer or English labels, USD or KHR display, notification access, role switching through sign-in, and session-aware account menus.", "Implemented"),
    ("Shared data", "API hydration", "Load properties, bookings, notifications, conversations, promotions, blocked dates, settings and users at portal startup and populate shared dashboard state.", "API integrated"),
    ("Owner dashboard", "Portfolio overview", "Display counts for properties and bookings, payment totals, recent reservations and operational shortcuts from API-loaded data.", "API-backed summary"),
    ("Owner properties", "Listing management", "List owner properties, open details, create or edit listing fields, upload a property photo, submit new listings for review, and change allowed listing status.", "API integrated"),
    ("Owner rooms", "Inventory management", "Load room types for a property, add or edit room name, bed, capacity, nightly price and inventory, then save the room collection.", "API integrated"),
    ("Owner pricing", "Nightly rates", "Load property room data, update room prices, and persist the change through the property API.", "API integrated"),
    ("Owner calendar", "Blocked dates", "Display booking and blocked-date information and save availability changes through the blocked-date API.", "API integrated"),
    ("Owner bookings", "Reservation management", "List bookings, open a dynamic booking detail page, view payment and guest details, and apply valid owner status transitions.", "API integrated"),
    ("Owner messages", "Guest communication", "List booking conversations, load message history, select a conversation and send a new message.", "API integrated"),
    ("Owner reviews", "Public responses", "Load reviews for the owner's properties, search feedback, calculate the current average rating, and create or edit a public response.", "API integrated"),
    ("Owner notifications", "Operational alerts", "Display API notifications and persist read status through the notification endpoint.", "API integrated"),
    ("Owner reporting", "Earnings and analytics", "Summarize API-loaded booking totals and six-month booking and revenue trends; show supporting school-project charts.", "Partly API backed"),
    ("Owner account", "Verification payouts and profile", "Provide account, verification and payout screens for demonstrating the intended workflow without an external identity provider, bank payout service or account-profile update endpoint.", "Demonstration UI"),
    ("Administrator dashboard", "Marketplace overview", "Display API-derived property, booking and revenue totals with shortcuts to administrative work areas.", "API-backed summary"),
    ("User administration", "Traveler and owner accounts", "List users, filter travelers or owners, and suspend or reactivate an account with administrator authorization.", "API integrated"),
    ("Property moderation", "Listing review", "List all properties for administrators, inspect listing details, and publish, reject, pause or restore a property through the status endpoint.", "API integrated"),
    ("Booking administration", "Reservation oversight", "List all bookings, open booking details, inspect payment state, and apply administrator-allowed status changes.", "API integrated"),
    ("Platform management", "Promotions and settings", "Load and create promotion codes; read and update commission, maintenance, instant-booking and payout settings.", "API integrated"),
    ("Administrator secondary screens", "Finance moderation content support and audit", "Present finance, verification, moderation, catalog, content, support and audit-log workspaces; these screens currently combine API-loaded records with demonstration data and local actions.", "Partial demonstration"),
]


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=90, start=100, bottom=90, end=100):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for side, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        tag = "w:" + side
        node = tc_mar.find(qn(tag))
        if node is None:
            node = OxmlElement(tag)
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_repeat_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def prevent_row_split(row):
    tr_pr = row._tr.get_or_add_trPr()
    cant_split = OxmlElement("w:cantSplit")
    tr_pr.append(cant_split)


def set_table_borders(table, color="D9D9D9", size="6"):
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.find(qn("w:tblBorders"))
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = "w:" + edge
        border = borders.find(qn(tag))
        if border is None:
            border = OxmlElement(tag)
            borders.append(border)
        border.set(qn("w:val"), "single")
        border.set(qn("w:sz"), size)
        border.set(qn("w:space"), "0")
        border.set(qn("w:color"), color)


def set_font(run, size, bold=False, color="000000"):
    run.font.name = "Arial"
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:ascii"), "Arial")
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:hAnsi"), "Arial")
    run.font.size = Pt(size)
    run.bold = bold
    run.font.color.rgb = RGBColor.from_string(color)


def add_inventory_table(doc, rows, font_size=8.2, vertical_margin=90):
    table = doc.add_table(rows=1, cols=4)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    widths = [Cm(4.1), Cm(4.8), Cm(13.3), Cm(3.4)]
    headers = ["Module", "Main feature", "Function list", "Current status"]
    header = table.rows[0]
    set_repeat_header(header)
    for index, (cell, label) in enumerate(zip(header.cells, headers)):
        cell.width = widths[index]
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        set_cell_shading(cell, "1F4E78")
        set_cell_margins(cell, top=105, bottom=105)
        paragraph = cell.paragraphs[0]
        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        paragraph.paragraph_format.space_after = Pt(0)
        run = paragraph.add_run(label)
        set_font(run, 8.5, bold=True, color="FFFFFF")
    for row_index, record in enumerate(rows):
        row = table.add_row()
        prevent_row_split(row)
        for index, (cell, value) in enumerate(zip(row.cells, record)):
            cell.width = widths[index]
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            if row_index % 2:
                set_cell_shading(cell, "F2F6FA")
            set_cell_margins(cell, top=vertical_margin, bottom=vertical_margin)
            paragraph = cell.paragraphs[0]
            paragraph.alignment = WD_ALIGN_PARAGRAPH.LEFT
            paragraph.paragraph_format.space_after = Pt(0)
            paragraph.paragraph_format.line_spacing = 1.0
            run = paragraph.add_run(value)
            set_font(run, font_size, bold=index in (0, 1))
    set_table_borders(table)
    return table


def insert_after(paragraph, text):
    new_p = OxmlElement("w:p")
    paragraph._p.addnext(new_p)
    new_para = paragraph._parent.add_paragraph()
    new_para._p.getparent().remove(new_para._p)
    new_para._p = new_p
    new_para._element = new_p
    new_para._parent = paragraph._parent
    new_para.style = paragraph.style
    new_para.paragraph_format.space_before = Pt(0)
    new_para.paragraph_format.space_after = Pt(0)
    new_para.paragraph_format.line_spacing = 0.9
    new_para.paragraph_format.keep_with_next = False
    new_para.paragraph_format.keep_together = False
    new_para.paragraph_format.page_break_before = False
    run = new_para.add_run(text)
    run.font.size = Pt(10)
    for existing in paragraph.runs:
        if existing.font.name:
            run.font.name = existing.font.name
            break
    return new_para


def remove_trailing_empty_paragraphs(doc):
    """Remove the source document's trailing blanks and manual page break."""
    body = doc._element.body
    for element in list(body)[-2::-1]:
        if element.tag != qn("w:p"):
            break
        text = "".join(element.itertext()).strip()
        if text:
            break
        body.remove(element)


def add_heading(doc, text, level):
    paragraph = doc.add_heading(text, level=level)
    paragraph.paragraph_format.keep_with_next = True
    for run in paragraph.runs:
        run.font.color.rgb = RGBColor(0, 0, 0)
    return paragraph


doc = Document(SOURCE)

for paragraph in doc.paragraphs:
    if paragraph.text.strip() == "14. Approval and Sign-off":
        insert_after(paragraph, "15. Implemented Functions by Project Module")
        break

in_toc = False
for paragraph in doc.paragraphs:
    text = paragraph.text.strip()
    if text == "Table of Contents":
        in_toc = True
        continue
    if in_toc:
        paragraph.paragraph_format.space_before = Pt(0)
        paragraph.paragraph_format.space_after = Pt(0)
        paragraph.paragraph_format.line_spacing = 0.92
        paragraph.paragraph_format.keep_with_next = False
        if text == "15. Implemented Functions by Project Module":
            break

remove_trailing_empty_paragraphs(doc)
section = doc.add_section(WD_SECTION.NEW_PAGE)
section.orientation = WD_ORIENT.LANDSCAPE
section.page_width, section.page_height = section.page_height, section.page_width
section.top_margin = Cm(1.5)
section.bottom_margin = Cm(1.5)
section.left_margin = Cm(1.5)
section.right_margin = Cm(1.5)

add_heading(doc, "15. Implemented Functions by Project Module", 1)
intro = doc.add_paragraph(
    "This section lists the functions present in the current KhmerStay source code as reviewed on 22 October 2026. "
    "Functions are grouped by project and module. Status labels identify functions that work through the local Go API, "
    "functions that need external credentials, and screens that remain part of the school-project demonstration."
)
intro.paragraph_format.space_after = Pt(10)

add_heading(doc, "15.1 Go API", 2)
p = doc.add_paragraph("The backend provides the REST API, authorization, SQLite persistence, local image storage, email OTP delivery, and conditional Bakong KHQR integration.")
p.paragraph_format.space_after = Pt(7)
add_inventory_table(doc, api_rows)

doc.add_paragraph().paragraph_format.space_after = Pt(2)
add_heading(doc, "15.2 Flutter Mobile Application", 2)
p = doc.add_paragraph("The Flutter application contains traveler and owner experiences in one codebase and connects its primary data flows to the Go API.")
p.paragraph_format.space_after = Pt(7)
add_inventory_table(doc, mobile_rows)

doc.add_paragraph().paragraph_format.space_after = Pt(2)
website_heading = add_heading(doc, "15.3 Next.js Website", 2)
website_heading.paragraph_format.page_break_before = True
p = doc.add_paragraph("The website provides owner and administrator portals. Core records are loaded from the Go API, while some external-service and secondary administration workflows remain demonstration screens.")
p.paragraph_format.space_after = Pt(7)
add_inventory_table(doc, website_rows, font_size=7.8, vertical_margin=30)

doc.core_properties.title = "KhmerStay Project Requirements"
doc.core_properties.subject = "Requirements and implemented function inventory for the KhmerStay API mobile application and website"
doc.save(OUTPUT)
print(OUTPUT)
