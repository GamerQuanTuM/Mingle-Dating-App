from datetime import datetime
from fastapi import UploadFile
from supabase import create_client, Client
import os
from dotenv import load_dotenv

load_dotenv()

supabase_api = os.getenv("SUPABASE_API")
supabase_service_key = os.getenv("SUPABASE_PRIVATE_KEY")
supabase_bucket_name = os.getenv("SUPABASE_STORAGE_NAME")
supabase: Client = create_client(supabase_api, supabase_service_key)


async def upload_to_supabase(file: UploadFile, file_type: str,user_id:str):
    # Read the file content as bytes
    file_content = await file.read()

    # Generate timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    # Split filename and extension
    filename_parts = file.filename.rsplit('.', 1)
    base_name = filename_parts[0]
    extension = filename_parts[1] if len(filename_parts) > 1 else ''

    # Create new filename with timestamp
    new_filename = f"{base_name}_{timestamp}.{extension}" if extension else f"{base_name}_{timestamp}"

    # Generate unique ID for the file path
    file_path = f"{file_type}/{user_id}/{new_filename}"

    # Upload the file to Supabase Storage
    supabase.storage.from_(supabase_bucket_name).upload(
        path=file_path,
        file=file_content,  # Pass the bytes directly
        file_options={"content-type": file.content_type}
    )

    # Get the public URL of the uploaded file
    file_url = supabase.storage.from_(
        supabase_bucket_name).get_public_url(file_path)

    return file_url
