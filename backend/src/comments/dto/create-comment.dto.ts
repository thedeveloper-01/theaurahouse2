import { IsString, IsNotEmpty, IsOptional, IsUUID } from 'class-validator';

export class CreateCommentDto {
  @IsString()
  @IsNotEmpty()
  text: string;

  @IsUUID()
  @IsOptional()
  parentCommentId?: string; // For nested/reply comments
}

